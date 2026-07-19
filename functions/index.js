const admin = require("firebase-admin");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {defineSecret} = require("firebase-functions/params");

admin.initializeApp();

const openAiKey = defineSecret("OPENAI_API_KEY");
const DEFAULT_MODEL = "gpt-5.4-mini";
const MAX_PROMPT_LENGTH = 1600;
const NOTIFICATION_TOPIC = "campus_all";
const NOTIFICATION_CHANNEL_ID = "campus_activity";

exports.askVuAi = onCall(
  {
    region: "us-central1",
    memory: "512MiB",
    timeoutSeconds: 60,
    secrets: [openAiKey],
  },
  async (request) => {
    const requester = await resolveRequester(request);

    const prompt = cleanText(request.data?.prompt, MAX_PROMPT_LENGTH);
    if (!prompt) {
      throw new HttpsError("invalid-argument", "Prompt is required.");
    }

    const apiKey = openAiKey.value();
    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "OPENAI_API_KEY is not configured for VU AI Desk.",
      );
    }

    const db = admin.firestore();
    const user = await readRequester(db, requester.uid);
    const campusContext = await buildCampusContext(db);
    const model = process.env.OPENAI_MODEL || DEFAULT_MODEL;

    const aiResponse = await askOpenAi({
      apiKey,
      model,
      prompt,
      user,
      campusContext,
    });

    await db.collection("ai_queries").add({
      userId: requester.uid,
      prompt,
      answer: aiResponse.answer,
      sources: aiResponse.sources,
      actions: aiResponse.actions,
      model,
      authSource: requester.source,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return aiResponse;
  },
);

exports.notifyOnAnnouncementCreated = onDocumentCreated(
  {
    region: "us-central1",
    document: "announcements/{announcementId}",
  },
  async (event) => {
    const data = event.data?.data() || {};
    const title = pickString(data, ["title", "headline", "subject"], "VU Pulse update");
    const body = pickString(
      data,
      ["content", "body", "description"],
      "A new campus notice has been published.",
    );
    const category = pickString(data, ["category", "type"], "Feed");
    const pinned = Boolean(data.isPinned || data.pinned);
    const urgent = category.toLowerCase().includes("urgent") || pinned;

    await publishCampusNotification({
      type: "announcement",
      sourceCollection: "announcements",
      sourceId: event.params.announcementId,
      title: urgent ? `Urgent: ${title}` : title,
      body,
      category,
      imageUrl: pickString(data, ["imageUrl", "coverUrl", "mediaUrl"], ""),
      priority: urgent ? "high" : "normal",
    });
  },
);

exports.notifyOnLivePostCreated = onDocumentCreated(
  {
    region: "us-central1",
    document: "live_posts/{postId}",
  },
  async (event) => {
    const data = event.data?.data() || {};
    const postType = pickString(data, ["type"], "live");
    const status = pickString(data, ["status"], "");
    const isLive = status === "live" || postType === "live";
    const isShortVideo = postType === "short_video" && status === "published";
    if (!isLive && !isShortVideo) return;

    const rawTitle = pickString(data, ["title", "name"], "Campus live");
    const title = isShortVideo ? `New VU video: ${rawTitle}` : `VU Live now: ${rawTitle}`;
    const body = pickString(
      data,
      ["description", "body", "caption"],
      isShortVideo
        ? "A new campus video is ready to watch."
        : "A campus live stream has started.",
    );

    await publishCampusNotification({
      type: "live",
      sourceCollection: "live_posts",
      sourceId: event.params.postId,
      title,
      body,
      category: pickString(data, ["category", "type"], isShortVideo ? "Video" : "Live"),
      imageUrl: pickString(data, ["coverUrl", "thumbnailUrl", "imageUrl"], ""),
      priority: isLive ? "high" : "normal",
    });
  },
);

exports.notifyOnEventCreated = onDocumentCreated(
  {
    region: "us-central1",
    document: "events/{eventId}",
  },
  async (event) => {
    const data = event.data?.data() || {};
    const status = pickString(data, ["status"], "upcoming").toLowerCase();
    if (status === "cancelled" || status === "ended") return;

    const title = pickString(data, ["title", "name", "eventTitle"], "Campus event");
    const body = pickString(
      data,
      ["description", "details", "body", "summary"],
      "A new campus event has been added.",
    );

    await publishCampusNotification({
      type: "event",
      sourceCollection: "events",
      sourceId: event.params.eventId,
      title: `Event: ${title}`,
      body,
      category: pickString(data, ["category", "type"], "Event"),
      imageUrl: pickString(data, ["imageUrl", "coverUrl", "bannerUrl"], ""),
      priority: status === "live" ? "high" : "normal",
    });
  },
);

exports.notifyOnPublicChatCreated = onDocumentCreated(
  {
    region: "us-central1",
    document: "public_chat/{messageId}",
  },
  async (event) => {
    const data = event.data?.data() || {};
    const senderId = pickString(data, ["senderId", "userId", "uid"], "");
    const senderName = pickString(
      data,
      ["senderName", "displayName", "username", "name"],
      "VU Student",
    );
    const text = pickString(
      data,
      ["text", "message", "content", "body"],
      "Shared a message in community chat.",
    );
    const replyToSenderId = pickString(data, ["replyToSenderId"], "");
    const isReply = Boolean(replyToSenderId && replyToSenderId !== senderId);
    const title = isReply
      ? `${senderName} replied to you`
      : `Community chat: ${senderName}`;

    if (isReply) {
      await sendUserNotification({
        userId: replyToSenderId,
        senderId,
        title,
        body: text,
        data: {
          type: "chat",
          sourceCollection: "public_chat",
          sourceId: event.params.messageId,
          category: "Chat reply",
          priority: "normal",
        },
      });
      return;
    }

    const notificationRef = await publishCampusNotification({
      type: "chat",
      sourceCollection: "public_chat",
      sourceId: event.params.messageId,
      title,
      body: text,
      category: "Community chat",
      imageUrl: pickString(data, ["mediaUrl", "imageUrl", "chatImageUrl"], ""),
      priority: "normal",
      topic: "",
    });
    await sendAudienceNotification({
      excludedUserId: senderId,
      title,
      body: text,
      data: {
        notificationId: notificationRef.id,
        type: "chat",
        sourceCollection: "public_chat",
        sourceId: event.params.messageId,
        category: "Community chat",
        priority: "normal",
        senderId,
      },
    });
  },
);

async function resolveRequester(request) {
  if (request.auth?.uid) {
    return {uid: request.auth.uid, source: "callable"};
  }

  const idToken = cleanText(request.data?.idToken, 6000);
  if (!idToken) {
    throw new HttpsError("unauthenticated", "Sign in to use VU AI Desk.");
  }

  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    if (!decoded.uid) {
      throw new Error("Verified token has no uid.");
    }
    return {uid: decoded.uid, source: "verified-id-token"};
  } catch (error) {
    console.warn("AI request had an invalid Firebase ID token.", error.message);
    throw new HttpsError("unauthenticated", "Sign in to use VU AI Desk.");
  }
}

async function readRequester(db, uid) {
  const doc = await db.collection("users").doc(uid).get();
  const data = doc.exists ? doc.data() : {};
  return {
    name: pickString(data, ["fullName", "displayName", "name"], "VU student"),
    role: pickString(data, ["role", "userRole", "accountType"], "student"),
    programme: pickString(data, ["programme", "program", "course"], ""),
    faculty: pickString(data, ["faculty", "school", "department"], ""),
  };
}

async function buildCampusContext(db) {
  const [
    announcements,
    pastPapers,
    resources,
    events,
    departments,
    guildPosts,
    discussions,
    communityPosts,
    faqs,
  ] = await Promise.all([
    readCollection(db, "announcements", 16, announcementSummary),
    readCollection(db, "past_papers", 14, resourceSummary),
    readCollection(db, "vu_resources", 14, resourceSummary),
    readCollection(db, "events", 14, eventSummary),
    readCollection(db, "departments", 30, departmentSummary),
    readCollection(db, "guild_posts", 12, postSummary),
    readCollection(db, "discussions", 12, discussionSummary),
    readCollection(db, "posts", 12, postSummary),
    readCollection(db, "ai_faqs", 40, faqSummary),
  ]);

  return {
    appPurpose:
      "VU Hub is a campus interaction system for Victoria University students, lecturers, guild leaders, and administrators. It combines verified announcements, VU Vault academic resources, campus events, department contacts, guild updates, community discussions, and AI support.",
    vclassGuide: VCLASS_GUIDE,
    collections: {
      announcements,
      past_papers: pastPapers,
      vu_resources: resources,
      events,
      departments,
      guild_posts: guildPosts,
      discussions,
      posts: communityPosts,
      ai_faqs: faqs,
    },
  };
}

async function publishCampusNotification({
  type,
  sourceCollection,
  sourceId,
  title,
  body,
  category,
  imageUrl,
  priority = "normal",
  topic = NOTIFICATION_TOPIC,
  targetUserId = "",
}) {
  const db = admin.firestore();
  const cleanTitle = cleanText(title, 90) || "VU Hub update";
  const cleanBody = cleanText(body, 180) || "New campus activity is available.";
  const cleanCategory = cleanText(category, 50) || "Campus";
  const notificationRef = await db.collection("notifications").add({
    type,
    sourceCollection,
    sourceId,
    title: cleanTitle,
    body: cleanBody,
    category: cleanCategory,
    imageUrl: cleanText(imageUrl, 600),
    priority,
    targetTopic: topic,
    targetUserId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  if (!topic) {
    return notificationRef;
  }

  const message = {
    topic,
    notification: {
      title: cleanTitle,
      body: cleanBody,
    },
    data: stringifyData({
      notificationId: notificationRef.id,
      type,
      sourceCollection,
      sourceId,
      title: cleanTitle,
      body: cleanBody,
      category: cleanCategory,
      priority,
    }),
    android: {
      priority: priority === "high" ? "high" : "normal",
      notification: {
        channelId: NOTIFICATION_CHANNEL_ID,
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  if (imageUrl) {
    message.android.notification.imageUrl = cleanText(imageUrl, 600);
    message.apns.fcm_options = {image: cleanText(imageUrl, 600)};
  }

  try {
    const messageId = await admin.messaging().send(message);
    await notificationRef.update({
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      fcmMessageId: messageId,
    });
  } catch (error) {
    console.error("Failed to send campus notification", {
      sourceCollection,
      sourceId,
      error: error.message,
    });
    await notificationRef.update({
      sendError: cleanText(error.message || "FCM send failed", 240),
      failedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return notificationRef;
}

async function sendUserNotification({userId, senderId, title, body, data}) {
  if (!userId || userId === senderId) return;
  const tokens = await collectUserTokens(admin.firestore(), userId);
  if (tokens.length === 0) return;

  const cleanTitle = cleanText(title, 90) || "VU Hub";
  const cleanBody = cleanText(body, 180) || "New chat activity.";
  const chunks = chunk(tokens, 500);
  await Promise.all(
    chunks.map((tokenChunk) =>
      admin.messaging().sendEachForMulticast({
        tokens: tokenChunk,
        notification: {
          title: cleanTitle,
          body: cleanBody,
        },
        data: stringifyData({
          ...data,
          title: cleanTitle,
          body: cleanBody,
          targetUserId: userId,
        }),
        android: {
          priority: "high",
          notification: {
            channelId: NOTIFICATION_CHANNEL_ID,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      }),
    ),
  );
}

async function sendAudienceNotification({excludedUserId, title, body, data}) {
  const tokens = await collectAudienceTokens(admin.firestore(), excludedUserId);
  if (tokens.length === 0) return;

  const cleanTitle = cleanText(title, 90) || "VU Hub";
  const cleanBody = cleanText(body, 180) || "New campus activity.";
  const chunks = chunk(tokens, 500);
  await Promise.all(
    chunks.map((tokenChunk) =>
      admin.messaging().sendEachForMulticast({
        tokens: tokenChunk,
        notification: {
          title: cleanTitle,
          body: cleanBody,
        },
        data: stringifyData({
          ...data,
          title: cleanTitle,
          body: cleanBody,
        }),
        android: {
          priority: "normal",
          notification: {
            channelId: NOTIFICATION_CHANNEL_ID,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      }),
    ),
  );
}

async function collectUserTokens(db, userId) {
  try {
    const snapshot = await db
      .collection("users")
      .doc(userId)
      .collection("notificationTokens")
      .limit(500)
      .get();
    return snapshot.docs
      .map((doc) => pickString(doc.data() || {}, ["token"], ""))
      .filter(Boolean);
  } catch (error) {
    console.warn("Failed to collect user notification tokens", {
      userId,
      error: error.message,
    });
    return [];
  }
}

async function collectAudienceTokens(db, excludedUserId) {
  try {
    const snapshot = await db
      .collectionGroup("notificationTokens")
      .limit(5000)
      .get();
    return snapshot.docs
      .filter((doc) => {
        const parentUserId = doc.ref.parent.parent?.id || "";
        return parentUserId && parentUserId !== excludedUserId;
      })
      .map((doc) => pickString(doc.data() || {}, ["token"], ""))
      .filter(Boolean);
  } catch (error) {
    console.warn("Failed to collect audience notification tokens", {
      excludedUserId,
      error: error.message,
    });
    return [];
  }
}

function chunk(items, size) {
  const chunks = [];
  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }
  return chunks;
}

function stringifyData(data) {
  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, String(value || "")]),
  );
}

const VCLASS_GUIDE = [
  {
    topic: "VClass overview",
    guidance:
      "VClass is the university student portal for modules, course materials, lectures, timetables, exams and assessments, financial statements, tutorials, elections, help and support, academic requests and applications, VU Shop orders, and settings.",
  },
  {
    topic: "Course materials",
    guidance:
      "For course materials, direct students to VClass > My Modules. VClass describes materials as PDFs, Word documents, and presentations organized by week. The student should open the relevant module and check its weekly materials/downloads.",
  },
  {
    topic: "Lectures and timetable",
    guidance:
      "For lecture schedules, direct students to VClass > Lectures or VClass > My Timetable. The Lectures area links to the timetable and shows trimester teaching/exam date context when available.",
  },
  {
    topic: "Assessments and results",
    guidance:
      "For assignments/coursework, direct students to VClass > Exams & Assessments > Course Work. For scheduled exams, use Examinations. For published marks or statement of results, use Examination Results. Do not reveal or guess grades.",
  },
  {
    topic: "Requests and applications",
    guidance:
      "For resits/retakes, programme change, intake change, session change, exemption/credit transfer, and graduation clearance, direct students to VClass > Requests & Applications and the matching request type.",
  },
  {
    topic: "Finance and support",
    guidance:
      "For balances, statements, PDF downloads, and tuition payment actions, direct students to VClass > Financial Statements. For portal or student support, direct them to Help & Support. For how-to guidance, direct them to Tutorials.",
  },
  {
    topic: "Account settings",
    guidance:
      "For profile photo, password changes, and account activity/export, direct students to VClass > Settings. Never ask students to share passwords inside VU Hub AI.",
  },
];

async function readCollection(db, collectionName, limit, mapper) {
  try {
    const snapshot = await db.collection(collectionName).limit(limit).get();
    return snapshot.docs
      .map((doc) => mapper(doc.id, doc.data() || {}))
      .filter((item) => Object.keys(item).length > 1);
  } catch (error) {
    console.warn(`Failed to read ${collectionName}`, error.message);
    return [];
  }
}

function announcementSummary(id, data) {
  return compact({
    source: `announcement:${id}`,
    title: pickString(data, ["title", "headline", "subject"], ""),
    category: pickString(data, ["category", "type"], "General"),
    content: pickString(data, ["content", "body", "description"], ""),
    publishedBy: pickString(data, ["publishedBy", "author", "authorName"], ""),
  });
}

function resourceSummary(id, data) {
  return compact({
    source: `resource:${id}`,
    title: pickString(data, ["subject", "title", "name"], ""),
    faculty: pickString(data, ["faculty", "department", "school"], ""),
    fileType: pickString(data, ["fileType", "type", "extension"], ""),
    uploadedBy: pickString(data, ["uploadedBy", "lecturerName", "authorName"], ""),
  });
}

function eventSummary(id, data) {
  return compact({
    source: `event:${id}`,
    title: pickString(data, ["title", "name", "eventTitle"], ""),
    category: pickString(data, ["category", "type"], ""),
    location: pickString(data, ["location", "venue", "place"], ""),
    description: pickString(data, ["description", "details", "body", "summary"], ""),
  });
}

function departmentSummary(id, data) {
  return compact({
    source: `department:${id}`,
    name: pickString(data, ["name", "office", "title"], id),
    department: pickString(data, ["department", "faculty", "unit"], ""),
    role: pickString(data, ["role", "service", "description"], ""),
    email: pickString(data, ["email", "contactEmail"], ""),
    location: pickString(data, ["location", "officeLocation"], ""),
    keywords: Array.isArray(data.keywords) ? data.keywords.slice(0, 8) : [],
  });
}

function postSummary(id, data) {
  return compact({
    source: `post:${id}`,
    title: pickString(data, ["title", "topic", "subject"], ""),
    category: pickString(data, ["category", "tag", "type"], ""),
    body: pickString(data, ["caption", "content", "body", "text", "description"], ""),
    author: pickString(data, ["authorName", "postedBy", "displayName"], ""),
  });
}

function discussionSummary(id, data) {
  return compact({
    source: `discussion:${id}`,
    title: pickString(data, ["title", "topic", "subject"], ""),
    category: pickString(data, ["category", "tag", "topicType"], ""),
    body: pickString(data, ["body", "content", "text", "description"], ""),
    resolved: Boolean(data.isResolved || data.resolved || data.closed),
  });
}

function faqSummary(id, data) {
  return compact({
    source: `faq:${id}`,
    question: pickString(data, ["question", "title", "prompt"], ""),
    answer: pickString(data, ["answer", "content", "response"], ""),
    category: pickString(data, ["category", "topic", "type"], ""),
  });
}

async function askOpenAi({apiKey, model, prompt, user, campusContext}) {
  const system = [
    "You are VU AI Desk, the official AI assistant inside VU Hub.",
    "Answer as a helpful Victoria University campus assistant.",
    "Use the supplied campus_context first. Do not invent deadlines, fees, policies, office locations, or lecturer names.",
    "If the answer is not in context, say what is missing and route the student to the best office or app section.",
    "Never reveal passwords, private chats, hidden user records, API keys, internal Firestore paths, or raw document IDs unless they are needed as source labels.",
    "For academic work, help students study and understand; do not write dishonest submissions for them.",
    "Return only valid JSON with answer, sources, and actions.",
  ].join(" ");

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      input: [
        {
          role: "system",
          content: system,
        },
        {
          role: "user",
          content: JSON.stringify({
            user,
            question: prompt,
            campus_context: campusContext,
          }),
        },
      ],
      max_output_tokens: 900,
      text: {
        format: {
          type: "json_schema",
          name: "vu_ai_response",
          strict: true,
          schema: {
            type: "object",
            additionalProperties: false,
            properties: {
              answer: {
                type: "string",
                description: "A clear, friendly answer for the student.",
              },
              sources: {
                type: "array",
                maxItems: 6,
                items: {type: "string"},
              },
              actions: {
                type: "array",
                maxItems: 5,
                items: {type: "string"},
              },
            },
            required: ["answer", "sources", "actions"],
          },
        },
      },
    }),
  });

  const payload = await response.json();
  if (!response.ok) {
    console.error("OpenAI request failed", payload);
    throw new HttpsError("internal", "VU AI could not prepare an answer.");
  }

  return normalizeAiResponse(parseOutputJson(payload));
}

function parseOutputJson(payload) {
  const text =
    payload.output_text ||
    (payload.output || [])
      .flatMap((item) => item.content || [])
      .map((content) => content.text || "")
      .join("");
  if (!text) {
    throw new HttpsError("internal", "VU AI returned an empty response.");
  }
  try {
    return JSON.parse(text);
  } catch (error) {
    console.error("Failed to parse AI JSON", text);
    throw new HttpsError("internal", "VU AI returned an invalid response.");
  }
}

function normalizeAiResponse(data) {
  return {
    answer: cleanText(data.answer, 2400) || "I could not prepare an answer.",
    sources: Array.isArray(data.sources)
      ? data.sources.map((item) => cleanText(item, 80)).filter(Boolean).slice(0, 6)
      : [],
    actions: Array.isArray(data.actions)
      ? data.actions.map((item) => cleanText(item, 80)).filter(Boolean).slice(0, 5)
      : [],
  };
}

function compact(data) {
  return Object.fromEntries(
    Object.entries(data).filter(([, value]) => {
      if (Array.isArray(value)) return value.length > 0;
      return value !== null && value !== undefined && value !== "";
    }),
  );
}

function pickString(data, keys, fallback) {
  for (const key of keys) {
    const value = data[key];
    if (typeof value === "string" && value.trim()) {
      return cleanText(value, 420);
    }
  }
  return fallback;
}

function cleanText(value, maxLength) {
  if (typeof value !== "string") return "";
  return value
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, maxLength);
}
