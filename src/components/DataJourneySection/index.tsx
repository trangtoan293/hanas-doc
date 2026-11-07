import React, {lazy, Suspense, useRef, useState} from 'react';
import {useGSAP} from '@gsap/react';
import {gsap} from 'gsap';
import {ScrollTrigger} from 'gsap/ScrollTrigger';
import {
  getNavbarHeight,
  scheduleScrollTriggerRefresh,
  useDesktopMotion,
} from '@site/src/hooks/useScrollStage';
import DashboardPanel from './DashboardPanel';
import RecordStoryOverlay, {MobileRecordEvidence} from './RecordStoryOverlay';
import {useColorMode} from '@docusaurus/theme-common';
import useLandingCopy, {type LandingCopy} from '@site/src/components/landingCopy';
import styles from './styles.module.css';

const JourneyCanvas = lazy(() => import('./JourneyCanvas'));

interface StoryCanvasBoundaryProps {
  children: React.ReactNode;
}

interface StoryCanvasBoundaryState {
  failed: boolean;
}

class StoryCanvasBoundary extends React.Component<StoryCanvasBoundaryProps, StoryCanvasBoundaryState> {
  state: StoryCanvasBoundaryState = {failed: false};

  static getDerivedStateFromError(): StoryCanvasBoundaryState {
    return {failed: true};
  }

  render(): React.ReactNode {
    if (this.state.failed) {
      return (
        <div className={styles.canvasFallback} aria-hidden="true">
          {Array.from({length: 18}, (_, index) => <span key={index} />)}
        </div>
      );
    }

    return this.props.children;
  }
}

const CHAPTER_COUNT = 5;
const stageThresholds = [0.17, 0.37, 0.57, 0.77];

function stageFromProgress(progress: number): number {
  const nextStage = stageThresholds.findIndex((threshold) => progress < threshold);
  return nextStage === -1 ? CHAPTER_COUNT - 1 : nextStage;
}

if (typeof window !== 'undefined') {
  gsap.registerPlugin(useGSAP, ScrollTrigger);
}

export default function DataJourneySection(): React.JSX.Element {
  const sectionRef = useRef<HTMLElement>(null);
  const stageRef = useRef<HTMLDivElement>(null);
  const canvasLayerRef = useRef<HTMLDivElement>(null);
  const dashboardRef = useRef<HTMLDivElement>(null);
  const copy: LandingCopy = useLandingCopy();
  const {colorMode} = useColorMode();
  const {journey} = copy;
  const progressRef = useRef(0);
  const enhancedStory = useDesktopMotion();
  const [activeStage, setActiveStage] = useState(0);

  useGSAP(
    () => {
      const section = sectionRef.current;
      const stage = stageRef.current;
      const dashboard = dashboardRef.current;
      const canvasLayer = canvasLayerRef.current;

      if (!enhancedStory || !section || !stage || !dashboard || !canvasLayer) return;

      const storyState = {progress: 0};
      const dashboardItems = dashboard.querySelectorAll<HTMLElement>('[data-dashboard-item]');
      const dashboardBars = dashboard.querySelectorAll<HTMLElement>('[data-dashboard-bar]');
      const dashboardPath = dashboard.querySelector<SVGPathElement>('[data-dashboard-path]');

      gsap.set(dashboard, {
        autoAlpha: 0,
        clipPath: 'inset(18% 18% 18% 18% round 18px)',
        rotateX: 9,
        scale: 0.82,
        transformPerspective: 1400,
        xPercent: -50,
        y: 28,
        yPercent: -50,
      });
      gsap.set(dashboardItems, {autoAlpha: 0, y: 18});
      gsap.set(dashboardBars, {scaleY: 0, transformOrigin: '50% 100%'});
      if (dashboardPath) {
        gsap.set(dashboardPath, {strokeDasharray: 1, strokeDashoffset: 1});
      }

      const updateStory = () => {
        const progress = storyState.progress;
        progressRef.current = progress;
        section.style.setProperty('--story-progress', progress.toFixed(4));

        const nextStage = stageFromProgress(progress);
        setActiveStage((currentStage) => currentStage === nextStage ? currentStage : nextStage);
      };

      const timeline = gsap.timeline({
        defaults: {ease: 'none'},
        scrollTrigger: {
          anticipatePin: 1,
          end: () => `+=${Math.max(window.innerHeight * 5.4, 3800)}`,
          invalidateOnRefresh: true,
          pin: stage,
          pinSpacing: true,
          scrub: 0.65,
          start: () => `top top+=${getNavbarHeight()}`,
          trigger: section,
        },
      });

      ['nguon', 'thu-nhan', 'xu-ly', 'tin-cay', 'gia-tri'].forEach((label, index) => {
        timeline.addLabel(label, index);
      });

      timeline.to(storyState, {
        duration: CHAPTER_COUNT,
        progress: 1,
        onUpdate: updateStory,
      }, 0);

      timeline.to(canvasLayer, {duration: 0.6, opacity: 0.2, scale: 0.94}, 3.78);
      timeline.to(
        dashboard,
        {
          autoAlpha: 1,
          clipPath: 'inset(0% 0% 0% 0% round 12px)',
          duration: 0.58,
          ease: 'power3.out',
          rotateX: 0,
          scale: 1,
          y: 0,
        },
        3.8,
      );
      timeline.to(
        dashboardItems,
        {autoAlpha: 1, duration: 0.34, ease: 'power2.out', stagger: 0.035, y: 0},
        4.05,
      );
      timeline.to(
        dashboardBars,
        {duration: 0.46, ease: 'back.out(1.4)', scaleY: 1, stagger: 0.035},
        4.1,
      );
      if (dashboardPath) {
        timeline.to(
          dashboardPath,
          {duration: 0.55, ease: 'power2.inOut', strokeDashoffset: 0},
          4.08,
        );
      }

      updateStory();

      const cancelRefresh = scheduleScrollTriggerRefresh();

      return () => {
        cancelRefresh();
        progressRef.current = 0;
        section.style.removeProperty('--story-progress');
      };
    },
    {dependencies: [enhancedStory], revertOnUpdate: true, scope: sectionRef},
  );

  return (
    <section className={styles.section} ref={sectionRef} aria-label={journey.ariaLabel}>
      <div className={styles.pinnedStage} ref={stageRef}>
        <div className={styles.atmosphere} aria-hidden="true" />

        <div className={`container ${styles.stageLayout}`}>
          <div className={styles.storyColumn}>
            <span className={styles.sectionEyebrow}>{journey.eyebrow}</span>

            <div className={styles.chapterStack}>
              {journey.chapters.map((chapter, index) => (
                <article
                  className={`${styles.chapter} ${index === activeStage ? styles.chapterActive : ''}`}
                  key={chapter.title}
                >
                  <span className={styles.chapterNumber}>{String(index + 1).padStart(2, '0')}</span>
                  <h2>{chapter.title}</h2>
                  <p>{chapter.description}</p>
                  <span className={styles.chapterOutcome}>{chapter.outcome}</span>
                  <MobileRecordEvidence stage={index} copy={copy} />
                </article>
              ))}
            </div>

            <div className={styles.scrollCue} aria-hidden="true">
              <span />
              {journey.scrollCue}
            </div>
          </div>

          <div className={styles.visualStage}>
            <div className={styles.canvasLayer} ref={canvasLayerRef}>
              {enhancedStory ? (
                <StoryCanvasBoundary>
                  <Suspense fallback={<div className={styles.canvasLoader} aria-hidden="true"><span /></div>}>
                    <JourneyCanvas progressRef={progressRef} sources={copy.sources} light={colorMode === 'light'} />
                  </Suspense>
                </StoryCanvasBoundary>
              ) : null}
            </div>

            <div className={styles.visualLabel} aria-hidden="true">
              <span>{journey.visualLabel}</span>
              <strong>{String(activeStage + 1).padStart(2, '0')}</strong>
            </div>

            <RecordStoryOverlay activeStage={activeStage} copy={copy} />

            <div className={styles.dashboardWrap} ref={dashboardRef}>
              <DashboardPanel copy={copy.dashboard} />
            </div>
          </div>
        </div>

        <div className={styles.progressRail} aria-label={`${journey.step} ${activeStage + 1} ${journey.of} ${CHAPTER_COUNT}`}>
          <span className={styles.progressRunway} aria-hidden="true" />
          <div className={styles.progressSteps}>
            {journey.labels.map((label, index) => (
              <span className={index <= activeStage ? styles.progressStepActive : ''} key={label}>
                <i>{String(index + 1).padStart(2, '0')}</i>
                {label}
              </span>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
