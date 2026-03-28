exports.handler = async (event) => {
  const GOOGLE_SCRIPT_URL =
    'https://script.google.com/macros/s/AKfycbwTQnJtJJ7LmYAT1UeA1kKNrxwmZswzKP4eNcMWKqIG7K10fLFiqaoYVekLKlu0vjdB/exec';

  console.log('Incoming request:', {
    method: event.httpMethod,
    body: event.body,
  });

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

  try {
    const payload = JSON.parse(event.body || '{}');

    console.log('Parsed payload:', payload);

    const response = await fetch(GOOGLE_SCRIPT_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const text = await response.text();

    console.log('Google response:', {
      status: response.status,
      body: text,
    });

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        ok: true,
        scriptStatus: response.status,
      }),
    };
  } catch (error) {
    console.error('Function error:', error);

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