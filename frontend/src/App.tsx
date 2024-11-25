import React, { useState, useEffect } from 'react';
import './App.css';

const apiUrl = process.env.REACT_APP_API_URL;

function App() {
  const [message, setMessage] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchGreeting = async () => {
      try {
        const response = await fetch(`${apiUrl}/hello`);
        if (!response.ok) {
          throw new Error('Failed to fetch greeting');
        }
        const data = await response.json();
        setMessage(data.message);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An error occurred');
      } finally {
        setLoading(false);
      }
    };

    fetchGreeting();
  }, []);

  return (
    <div className="App">
      <header className="App-header">
        {loading && <p>Loading...</p>}
        {error && <p style={{ color: 'red' }}>Error: {error}</p>}
        {message && <p>Message from backend: {message}</p>}
        <p>
          Backend API URL: <code>{apiUrl}</code>
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
    </div>
  );
}

export default App;
