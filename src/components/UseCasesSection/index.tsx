import React from 'react';
import Link from '@docusaurus/Link';
import useLazyVideo, {posterOf} from '@site/src/hooks/useLazyVideo';
import useLandingCopy from '@site/src/components/landingCopy';
import styles from './styles.module.css';

interface UseCase {
  category: string;
  title: string;
  description: string;
  signal: string;
  video: string;
  link: string;
  more: string;
}

// Same order as useCases.items in landingCopy.
const useCaseMeta = [
  {signal: 'ASK / QUERY / EXPLAIN', video: '/video/dashboard-simple.mp4', link: '/docs/kapas/chat-with-data'},
  {signal: 'CONNECT / MODEL / EXPLORE', video: '/video/dashboard-with-manager.mp4', link: '/docs/ontology/explore'},
  {signal: 'QUERY / SAVE / SHARE', video: '/video/computer.mp4', link: '/docs/query/sql-studio'},
  {signal: 'SCHEDULE / RUN / TRACE', video: '/video/modern-dashboard-monitoring.mp4', link: '/docs/transform/pipelines'},
];

function UseCaseCard({category, title, description, signal, video, link, more}: UseCase): React.JSX.Element {
  const videoRef = useLazyVideo();
  return (
    <article className={styles.card}>
      <div className={styles.visual} aria-hidden="true">
        <video
          ref={videoRef}
          muted
          loop
          playsInline
          preload="none"
          poster={posterOf(video)}
          aria-hidden="true"
        >
          <source src={video} type="video/mp4" />
        </video>
        <div className={styles.visualTop}>
          <span className={styles.visualSignal}>{signal}</span>
        </div>
      </div>
      <div className={styles.cardContent}>
        <span className={styles.category}>{category}</span>
        <h3>{title}</h3>
        <p>{description}</p>
        <Link to={link}>
          {more} <span aria-hidden="true">↗</span>
        </Link>
      </div>
    </article>
  );
}

export default function UseCasesSection(): React.JSX.Element {
  const {useCases} = useLandingCopy();
  return (
    <section className={styles.section}>
      <div className="container">
        <div className={styles.header}>
          <h2>
            {useCases.titleLines[0]}
            <br className="landingDesktopBreak" />{' '}
            {useCases.titleLines[1]}
          </h2>
        </div>

        <div className={styles.rail} aria-label={useCases.railAria}>
          {useCases.items.map((item, index) => (
            <UseCaseCard key={item.title} {...item} {...useCaseMeta[index]} more={useCases.more} />
          ))}
        </div>
      </div>
    </section>
  );
}
