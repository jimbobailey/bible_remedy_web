exports.handler = async (event) => {
  const GOOGLE_SCRIPT_URL =
    'PASTE_YOUR_GOOGLE_APPS_SCRIPT_EXEC_URL_HERE';

  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        ok: false,
        error: 'Method not allowed',
      }),
    };
  }

  if (
    !GOOGLE_SCRIPT_URL ||
    GOOGLE_SCRIPT_URL === 'https://script.google.com/macros/s/AKfycbwTQnJtJJ7LmYAT1UeA1kKNrxwmZswzKP4eNcMWKqIG7K10fLFiqaoYVekLKlu0vjdB/exec'
  ) {
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        ok: false,
        error: 'Google Script URL not set',
      }),
    };
  }

  try {
    const payload = JSON.parse(event.body || '{}');

    const response = await fetch(GOOGLE_SCRIPT_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const text = await response.text();

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        ok: true,
        scriptStatus: response.status,
        scriptBody: text,
      }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        ok: false,
        error: String(error),
      }),
    };
  }
};