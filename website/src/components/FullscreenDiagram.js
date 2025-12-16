import React, { useEffect, useState, useRef } from 'react';
import mermaid from 'mermaid';
import { TransformWrapper, TransformComponent } from "react-zoom-pan-pinch";

// Configure mermaid to not restrict width
mermaid.initialize({ 
  startOnLoad: false,
  theme: 'default',
  securityLevel: 'loose',
  flowchart: { useMaxWidth: false },
  er: { useMaxWidth: false }
});

const FullscreenDiagram = ({ definition }) => {
  const [svg, setSvg] = useState('');
  const [isOpen, setIsOpen] = useState(false);
  const elementId = useRef(`mermaid-${Math.random().toString(36).substr(2, 9)}`);

  useEffect(() => {
    const renderDiagram = async () => {
      try {
        const { svg } = await mermaid.render(elementId.current, definition);
        setSvg(svg);
      } catch (error) {
        console.error('Mermaid rendering failed:', error);
        setSvg('<div style="color:red">Failed to render diagram</div>');
      }
    };
    renderDiagram();
  }, [definition]);

  return (
    <>
      <style>{`
        .mermaid-preview-box svg {
          width: 100% !important;
          height: auto !important;
          max-height: 500px;
          cursor: zoom-in;
        }
      `}</style>

      {/* Inline Display */}
      <div 
        className="mermaid-container" 
        style={{ 
          border: '1px solid #eee', 
          padding: '10px', 
          borderRadius: '8px', 
          textAlign: 'center',
          backgroundColor: 'var(--ifm-background-color)',
          transition: 'box-shadow 0.3s ease'
        }}
        onClick={() => setIsOpen(true)}
        title="Click to enlarge"
      >
        {svg ? (
          <div 
            className="mermaid-preview-box"
            dangerouslySetInnerHTML={{ __html: svg }} 
            style={{ display: 'flex', justifyContent: 'center' }}
          />
        ) : (
          <div>Loading diagram...</div>
        )}
        <div style={{fontSize: '0.8rem', color: 'var(--ifm-color-content-secondary)', marginTop: '8px'}}>
          🔍 Click to open full view
        </div>
      </div>

      {/* Fullscreen Modal */}
      {isOpen && (
        <div style={{
          position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', 
          backgroundColor: 'rgba(0,0,0,0.9)', zIndex: 9999, display: 'flex', 
          justifyContent: 'center', alignItems: 'center',
          backdropFilter: 'blur(5px)'
        }}
        >
          <button 
            onClick={() => setIsOpen(false)}
            style={{
              position: 'absolute', top: '20px', right: '20px', zIndex: 10000,
              background: 'rgba(255,255,255,0.1)', color: 'white', border: '1px solid rgba(255,255,255,0.3)', 
              borderRadius: '50%', width: '48px', height: '48px',
              cursor: 'pointer', fontSize: '28px', display: 'flex', alignItems: 'center', justifyContent: 'center',
              transition: 'all 0.2s'
            }}
            onMouseEnter={(e) => {
                e.currentTarget.style.background = 'rgba(255,255,255,0.2)';
                e.currentTarget.style.transform = 'scale(1.1)';
            }}
            onMouseLeave={(e) => {
                e.currentTarget.style.background = 'rgba(255,255,255,0.1)';
                e.currentTarget.style.transform = 'scale(1)';
            }}
          >
            ×
          </button>
          
          <TransformWrapper
            initialScale={1}
            minScale={0.1}
            maxScale={50}
            centerOnInit={true}
            limitToBounds={false}
          >
            <TransformComponent wrapperStyle={{width: '100vw', height: '100vh'}}>
              <div 
                style={{
                    width: '100vw', 
                    height: '100vh', 
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'center', 
                }}
              >
                 <div 
                    style={{
                        // Removed white background
                        padding: '20px', 
                        borderRadius: '8px',
                        display: 'inline-block',
                        // Invert colors to make black lines white on the dark modal background
                        filter: 'invert(1) hue-rotate(180deg)'
                    }}
                    onClick={(e) => e.stopPropagation()}
                    dangerouslySetInnerHTML={{ __html: svg }} 
                 />
              </div>
            </TransformComponent>
          </TransformWrapper>
          
          <div style={{
              position: 'absolute', bottom: '30px', color: 'rgba(255,255,255,0.7)', 
              background: 'rgba(0,0,0,0.5)', padding: '8px 16px', borderRadius: '20px',
              pointerEvents: 'none', border: '1px solid rgba(255,255,255,0.1)',
              fontSize: '0.9rem'
          }}>
              Scroll to Zoom • Drag to Pan
          </div>
        </div>
      )}
    </>
  );
};

export default FullscreenDiagram;
