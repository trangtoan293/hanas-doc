import React, {useState} from 'react';
import useLazyVideo, {posterOf} from '@site/src/hooks/useLazyVideo';
import useLandingCopy from '@site/src/components/landingCopy';
import styles from './styles.module.css';

type TabId = 'foundation' | 'intelligence' | 'governance';

// Same order as tabs.items in landingCopy.
const experienceMeta: Array<{id: TabId; video: string}> = [
  {id: 'intelligence', video: '/video/main-background-landing-page.mp4'},
  {id: 'foundation', video: '/video/background-data.mp4'},
  {id: 'governance', video: '/video/digital-dashboard.mp4'},
];

export default function TabNavigation(): React.JSX.Element {
  const {tabs} = useLandingCopy();
  const experiences = tabs.items.map((item, index) => ({...item, ...experienceMeta[index]}));
  const [activeTab, setActiveTab] = useState<TabId>(experienceMeta[0].id);
  const activeExperience = experiences.find((experience) => experience.id === activeTab) ?? experiences[0];
  const videoRef = useLazyVideo([activeExperience.video]);

  const moveTab = (direction: number) => {
    const currentIndex = experiences.findIndex((experience) => experience.id === activeTab);
    const nextIndex = (currentIndex + direction + experiences.length) % experiences.length;
    setActiveTab(experiences[nextIndex].id);
  };

  return (
    <section className={styles.section}>
      <div className="container">
        <div className={styles.header}>
          <h2>
            {tabs.titleLines[0]}
            <br className="landingDesktopBreak" />{' '}
            {tabs.titleLines[1]}
          </h2>
          <p>{tabs.intro}</p>
        </div>

        <div className={styles.experienceShell}>
          <div className={styles.tabList} role="tablist" aria-label={tabs.listAria}>
            {experiences.map((experience) => (
              <button
                key={experience.id}
                id={`tab-${experience.id}`}
                type="button"
                role="tab"
                aria-selected={activeTab === experience.id}
                aria-controls={`panel-${experience.id}`}
                tabIndex={activeTab === experience.id ? 0 : -1}
                className={`${styles.tabButton} ${activeTab === experience.id ? styles.tabButtonActive : ''}`}
                onClick={() => setActiveTab(experience.id)}
                onKeyDown={(event) => {
                  if (event.key === 'ArrowDown' || event.key === 'ArrowRight') {
                    event.preventDefault();
                    moveTab(1);
                  }
                  if (event.key === 'ArrowUp' || event.key === 'ArrowLeft') {
                    event.preventDefault();
                    moveTab(-1);
                  }
                }}
              >
                <strong>{experience.label}</strong>
              </button>
            ))}
          </div>

          <article
            id={`panel-${activeExperience.id}`}
            role="tabpanel"
            aria-labelledby={`tab-${activeExperience.id}`}
            className={styles.panel}
          >
            <div className={styles.panelContent}>
              <div className={styles.panelNarrative}>
                <span className={styles.panelEyebrow}>{activeExperience.eyebrow}</span>
                <h3>{activeExperience.title}</h3>
                <p>{activeExperience.description}</p>
              </div>
              <ul>
                {activeExperience.bullets.map((bullet) => (
                  <li key={bullet}>
                    <span aria-hidden="true">✓</span>
                    {bullet}
                  </li>
                ))}
              </ul>
            </div>

            <div className={styles.flowVisual} aria-hidden="true">
              <video
                key={activeExperience.video}
                className={styles.flowVideo}
                ref={videoRef}
                muted
                loop
                playsInline
                preload="none"
                poster={posterOf(activeExperience.video)}
              >
                <source src={activeExperience.video} type="video/mp4" />
              </video>
            </div>

            {/* A read-only caption of the flow, styled so it never reads as buttons. */}
            <div className={styles.flow}>
              <span className={styles.flowTitle}>{tabs.flowTitle}</span>
              <ol className={styles.flowStages}>
                {activeExperience.flow.map((stage) => (
                  <li key={stage}>{stage}</li>
                ))}
              </ol>
            </div>
          </article>
        </div>
      </div>
    </section>
  );
}
