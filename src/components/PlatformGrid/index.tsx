import React from 'react';
import Link from '@docusaurus/Link';
import useLazyVideo, {posterOf} from '@site/src/hooks/useLazyVideo';
import useLandingCopy from '@site/src/components/landingCopy';
import styles from './styles.module.css';

interface Capability {
  title: string;
  description: string;
  technologies: string[];
  video: string;
  link: string;
}

// Same order as grid.cards in landingCopy.
const capabilityMedia = [
  {technologies: ['Ontology', 'Kapas', 'Metric'], video: '/video/Enterprise AI Services.mp4', link: '/docs/kapas'},
  {technologies: ['Query Engine', 'Ingestion', 'Connector'], video: '/video/data-pipeline.mp4', link: '/docs/connect'},
  {technologies: ['Apache Iceberg', 'MinIO', 'Iceberg catalog'], video: '/video/data-sample.mp4', link: '/docs/query/iceberg-tables'},
  {technologies: ['dbt Studio', 'Pipeline', 'Spark'], video: '/video/processing-data.mp4', link: '/docs/transform'},
  {technologies: ['Keycloak', 'Hanas Catalog', 'Lineage'], video: '/video/Governance & Security.mp4', link: '/docs/govern'},
  {technologies: ['SQL Editor', 'Superset', 'Arrow Flight'], video: '/video/Data Access & BI.mp4', link: '/docs/query'},
];

function CapabilityCard({title, description, technologies, video, link, learnMore}: Capability & {learnMore: string}): React.JSX.Element {
  const videoRef = useLazyVideo();
  return (
    <Link to={link} className={styles.card} aria-label={`${learnMore} ${title}`}>
      <div className={styles.cardMedia} aria-hidden="true">
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
      </div>
      <div className={styles.cardContent}>
        <h3>{title}</h3>
        <p>{description}</p>
        <div className={styles.cardFooter}>
          <div className={styles.technologies}>
            {technologies.map((technology) => (
              <span key={technology}>{technology}</span>
            ))}
          </div>
        </div>
      </div>
    </Link>
  );
}

export default function PlatformGrid(): React.JSX.Element {
  const {grid} = useLandingCopy();
  return (
    <section className={styles.section} id="capabilities">
      <div className="container">
        <div className={styles.header}>
          <h2>
            {grid.titleLines[0]}
            <br className="landingDesktopBreak" />{' '}
            {grid.titleLines[1]}
          </h2>
        </div>

        <div className={styles.grid}>
          {grid.cards.map((card, index) => (
            <CapabilityCard key={card.title} {...card} {...capabilityMedia[index]} learnMore={grid.learnMore} />
          ))}
        </div>
      </div>
    </section>
  );
}
