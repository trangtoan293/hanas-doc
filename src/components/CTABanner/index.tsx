import React from 'react';
import useLazyVideo from '@site/src/hooks/useLazyVideo';
import useLandingCopy from '@site/src/components/landingCopy';
import styles from './styles.module.css';


export default function CTABanner(): React.JSX.Element {
  const {cta} = useLandingCopy();
  const videoRef = useLazyVideo();
  return (
    <section className={styles.section}>
      <div className="container">
        <div className={styles.shell}>
          <video
            className={styles.backgroundVideo}
            ref={videoRef}
            muted
            loop
            playsInline
            preload="none"
            poster="/img/poster/coding-monitor.webp"
            aria-hidden="true"
          >
            <source src="/video/coding-vertical.mp4" type="video/mp4" media="(max-width: 600px)" />
            <source src="/video/coding-monitor.mp4" type="video/mp4" />
          </video>
          <div className={styles.glow} aria-hidden="true" />
          <div className={styles.content}>
            <h2>
              {cta.titleLines[0]}
              <br className="landingDesktopBreak" />{' '}
              {cta.titleLines[1]}
            </h2>
            <p>{cta.body}</p>
            <div className={styles.actions}>
              <a
                href={`mailto:thunnv@katalyst.vn?subject=${encodeURIComponent(cta.mailSubject)}`}
                className={styles.primaryAction}
                aria-label={cta.actionAria}
              >
                {cta.action} <span aria-hidden="true">→</span>
              </a>
            </div>
          </div>

          <div className={styles.roadmap}>
            <div className={styles.roadmapHeader}>
              <span>{cta.roadmapTitle}</span>
            </div>
            {cta.steps.map((step, index) => (
              <div key={step.title} className={styles.roadmapStep}>
                <span>{String(index + 1).padStart(2, '0')}</span>
                <div>
                  <strong>{step.title}</strong>
                  <small>{step.description}</small>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
