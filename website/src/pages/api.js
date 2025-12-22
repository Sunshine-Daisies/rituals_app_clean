import React from 'react';
import Layout from '@theme/Layout';
import clsx from 'clsx';
import styles from './index.module.css'; // Reusing styles for consistency

export default function ApiDocs() {
  // Canlı sunucu adresi
  const API_URL = 'https://ritualsappclean-production.up.railway.app';
  const SWAGGER_URL = `${API_URL}/docs/`;

  return (
    <Layout title="API Reference" description="Rituals App API Documentation">
      <div className="container margin-vert--lg" style={{ maxWidth: '98%' }}>
        <div className="row">
          {/* Sol Taraf: Bilgilendirme */}
          <div className="col col--2">
            <div className="card shadow--md">
              <div className="card__header">
                <h3>🔑 Quick Start</h3>
              </div>
              <div className="card__body">
                <p>
                  <strong>Base URL:</strong><br />
                  <code style={{ fontSize: '0.75rem', wordBreak: 'break-all' }}>{API_URL}</code>
                </p>
                <hr />
                <p>
                  <strong>Auth:</strong><br />
                  <span style={{ fontSize: '0.8rem' }}>Bearer Token required.</span>
                </p>
                <div className="alert alert--info margin-bottom--sm" style={{ fontSize: '0.7rem', padding: '0.5rem' }}>
                  Header: <br />
                  <code>Authorization: Bearer &lt;token&gt;</code>
                </div>
                <hr />
                <p>
                  <strong>Test User:</strong><br />
                  <span style={{ fontSize: '0.75rem' }}>Email: </span><code style={{ fontSize: '0.7rem' }}>demo@rituals.app</code><br />
                  <span style={{ fontSize: '0.75rem' }}>Pass: </span><code style={{ fontSize: '0.7rem' }}>123456</code>
                </p>
                <hr />
                <p style={{ fontSize: '0.8rem' }}>
                  <strong>Responses:</strong><br />
                  <span className="badge badge--success">200</span> OK<br />
                  <span className="badge badge--warning">400</span> Bad Req<br />
                  <span className="badge badge--danger">401</span> Unauth
                </p>
                <hr />
                <p style={{ fontSize: '0.8rem' }}>
                  <strong>Version:</strong><br />
                  API v2.0
                </p>
              </div>
              <div className="card__footer">
                <a href={SWAGGER_URL} target="_blank" className="button button--primary button--block button--sm">
                  Open ↗
                </a>
              </div>
            </div>
          </div>

          {/* Sağ Taraf: Swagger Iframe */}
          <div className="col col--10">
            <div style={{
              height: '88vh',
              width: '100%',
              borderRadius: '10px',
              overflow: 'hidden',
              border: '1px solid var(--ifm-color-emphasis-200)',
              background: 'white' // Swagger is usually light theme
            }}>
              <iframe
                src={SWAGGER_URL}
                style={{ width: '100%', height: '100%', border: 'none' }}
                title="Swagger UI"
              />
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}
