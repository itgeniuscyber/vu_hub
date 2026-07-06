const admin = require("firebase-admin");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");

admin.initializeApp();

const openAiKey = defineSecret("OPENAI_API_KEY");
const DEFAULT_MODEL = "gpt-5.4-mini";
const MAX_PROMPT_LENGTH = 1600;

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
