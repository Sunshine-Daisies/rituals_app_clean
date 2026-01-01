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
      <style>{`
        .api-container {
          max-width: 98%;
          margin: 0 auto;
          padding: 1rem;
        }
        .api-row {
          display: flex;
          flex-direction: row;
          gap: 1rem;
        }
        .api-sidebar {
          flex: 0 0 200px;
          min-width: 180px;
        }
        .api-main {
          flex: 1;
        }
        .swagger-frame {
          height: 88vh;
          width: 100%;
          border-radius: 10px;
          overflow: hidden;
          border: 1px solid var(--ifm-color-emphasis-200);
          background: white;
        }
        .swagger-frame iframe {
          width: 100%;
          height: 100%;
          border: none;
        }
        
        /* Mobile responsive */
        @media screen and (max-width: 996px) {
          .api-sidebar {
            flex: 0 0 160px;
            min-width: 140px;
          }
          .swagger-frame {
            height: 75vh;
          }
        }
        
        @media screen and (max-width: 768px) {
          .api-row {
            flex-direction: column;
          }
          .api-sidebar {
            flex: 1;
            width: 100%;
            min-width: unset;
          }
          .swagger-frame {
            height: 70vh;
          }
        }
        
        @media screen and (max-width: 576px) {
          .api-container {
            padding: 0.5rem;
          }
          .swagger-frame {
            height: 60vh;
            border-radius: 8px;
          }
          .card__body {
            padding: 0.75rem !important;
          }
          .card__body p {
            margin-bottom: 0.5rem !important;
          }
        }
      `}</style>

      <div className="api-container margin-vert--lg">
        <div className="api-row">
          {/* Sol Taraf: Bilgilendirme */}
          <div className="api-sidebar">
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
          <div className="api-main">
            <div className="swagger-frame">
              <iframe
                src={SWAGGER_URL}
                title="Swagger UI"
              />
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}

