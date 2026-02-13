import { serve } from "https://deno.land/std@0.177.0/http/server.ts"

const ONESIGNAL_APP_ID = "e81fbf1a-1e59-4bc3-8254-1f738607b947";
const ONESIGNAL_REST_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY')!;

serve(async (req) => {
  try {
    const { record } = await req.json();
    console.log("Triggered for User:", record.user_id);

    if (!record.user_id) {
      console.error("No User ID found in record");
      return new Response("No user_id", { status: 400 });
    }

    const time = new Date().toLocaleTimeString();

    const response = await fetch('https://api.onesignal.com/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${ONESIGNAL_REST_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        include_aliases: { external_id: [record.user_id] },
        target_channel: "push",
        headings: { en: `🚨 ALARM: ${time}` },
        contents: { en: "Vibration detected on your vehicle!" },
        android_group: "alarm_" + Date.now(), // Force unique group every time
        priority: 10,
        android_channel_id: "35ea53a4-eb6e-4de9-a803-ca51691244e6",
        android_sound: "siren",
      }),
    });

    const result = await response.json();
    console.log("OneSignal Status:", response.status);
    console.log("OneSignal Response:", JSON.stringify(result));

    return new Response(JSON.stringify(result), { 
      headers: { "Content-Type": "application/json" },
      status: 200 
    });

  } catch (err) {
    console.error("Critical Function Error:", err.message);
    return new Response(err.message, { status: 500 });
  }
})