import React, {lazy, Suspense, useEffect, useRef, useState} from 'react';
import {useGSAP} from '@gsap/react';
import {gsap} from 'gsap';
import {ScrollTrigger} from 'gsap/ScrollTrigger';
import DashboardPanel from './DashboardPanel';
import RecordStoryOverlay, {MobileRecordEvidence} from './RecordStoryOverlay';
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

interface JourneyChapter {
  eyebrow: string;
  title: string;
  description: string;
  outcome: string;
}

const chapters: JourneyChapter[] = [
  {
    eyebrow: '01 — Dữ liệu phân tán',
    title: 'Dữ liệu rời rạc. Quyết định chậm.',
    description: 'Dữ liệu nằm ở nhiều hệ thống khiến báo cáo đến chậm và mỗi phòng ban có một cách hiểu khác nhau.',
    outcome: 'Báo cáo rời rạc · Đối soát thủ công',
  },
  {
    eyebrow: '02 — Hợp nhất',
    title: 'Mọi dữ liệu về cùng một nơi',
    description: 'Hanas thu thập batch và real-time về cùng một nơi mà không làm gián đoạn hệ thống nguồn.',
    outcome: 'Batch + real-time · Không gián đoạn nguồn',
  },
  {
    eyebrow: '03 — Chất lượng dữ liệu',
    title: 'Dữ liệu sai dừng trước báo cáo',
    description: 'Quy tắc chất lượng tách ngoại lệ khỏi dữ liệu hợp lệ, để sai lệch dừng lại trước khi thành quyết định.',
    outcome: 'Ngoại lệ tách riêng · Dữ liệu đúng đi tiếp',
  },
  {
    eyebrow: '04 — Một nguồn tin cậy',
    title: 'Một nguồn dữ liệu. Một cách hiểu.',
    description: 'Dữ liệu sạch được tổ chức theo Data Vault 2.0: business key trong Hub, ngữ cảnh trong Satellite và quan hệ trong Link.',
    outcome: 'Data Vault 2.0 · Cùng định nghĩa · Phân quyền rõ ràng',
  },
  {
    eyebrow: '05 — Sẵn sàng sử dụng',
    title: 'Chỉ số sẵn sàng cho quyết định',
    description: 'Cùng một dữ liệu phục vụ dashboard, API và ứng dụng AI — không phải tổng hợp lại cho từng nhu cầu.',
    outcome: 'Dashboard · API · AI',
  },
];

const chapterLabels = ['Phân tán', 'Hợp nhất', 'Chất lượng', 'Tin cậy', 'Giá trị'];
const stageThresholds = [0.17, 0.37, 0.57, 0.77];

function stageFromProgress(progress: number): number {
  const nextStage = stageThresholds.findIndex((threshold) => progress < threshold);
  return nextStage === -1 ? chapters.length - 1 : nextStage;
}

// Chương "Chất lượng" chia thành 5 nhịp: tiếp nhận → 3 quy tắc → phân luồng.
const qualityPhaseThresholds = [0.16, 0.36, 0.56, 0.76];

function qualityPhaseFromProgress(progress: number): number {
  const qualityStart = stageThresholds[1];
  const qualityEnd = stageThresholds[2];
  const qualityProgress = (progress - qualityStart) / (qualityEnd - qualityStart);
  const nextPhase = qualityPhaseThresholds.findIndex((threshold) => qualityProgress < threshold);
  return nextPhase === -1 ? qualityPhaseThresholds.length : nextPhase;
}

function useEnhancedStory(): boolean {
  const [enabled, setEnabled] = useState(false);

  useEffect(() => {
    const desktop = window.matchMedia('(min-width: 901px)');
    const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
    const update = () => setEnabled(desktop.matches && !reducedMotion.matches);

    desktop.addEventListener('change', update);
    reducedMotion.addEventListener('change', update);
    update();

    return () => {
      desktop.removeEventListener('change', update);
      reducedMotion.removeEventListener('change', update);
    };
  }, []);

  return enabled;
}

// --ifm-navbar-height là clamp() nên parseFloat trả NaN — đo thẳng phần tử navbar.
function getNavbarHeight(): number {
  const navbar = document.querySelector('.navbar');
  return navbar ? navbar.getBoundingClientRect().height : 0;
}

if (typeof window !== 'undefined') {
  gsap.registerPlugin(useGSAP, ScrollTrigger);
}

export default function DataJourneySection(): React.JSX.Element {
  const sectionRef = useRef<HTMLElement>(null);
  const stageRef = useRef<HTMLDivElement>(null);
  const canvasLayerRef = useRef<HTMLDivElement>(null);
  const dashboardRef = useRef<HTMLDivElement>(null);
  const progressRef = useRef(0);
  const enhancedStory = useEnhancedStory();
  const [activeStage, setActiveStage] = useState(0);
  const [qualityPhase, setQualityPhase] = useState(0);

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
        gsap.set(dashboardPath, {strokeDasharray: 620, strokeDashoffset: 620});
      }

      const updateStory = () => {
        const progress = storyState.progress;
        progressRef.current = progress;
        section.style.setProperty('--story-progress', progress.toFixed(4));

        const nextStage = stageFromProgress(progress);
        const nextQualityPhase = qualityPhaseFromProgress(progress);
        setActiveStage((currentStage) => currentStage === nextStage ? currentStage : nextStage);
        setQualityPhase((currentPhase) => currentPhase === nextQualityPhase ? currentPhase : nextQualityPhase);
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
        duration: chapters.length,
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

      // Trigger được tạo sau hydrate, thường muộn hơn sự kiện `load`, nên ScrollTrigger
      // không tự refresh và pin-spacer giữ nguyên chiều dài 0 -> cả chương trôi tuột.
      const refresh = () => ScrollTrigger.refresh();
      const refreshFrame = requestAnimationFrame(refresh);
      document.fonts?.ready.then(refresh);

      return () => {
        cancelAnimationFrame(refreshFrame);
        progressRef.current = 0;
        section.style.removeProperty('--story-progress');
      };
    },
    {dependencies: [enhancedStory], revertOnUpdate: true, scope: sectionRef},
  );

  return (
    <section className={styles.section} ref={sectionRef} aria-label="Hành trình dữ liệu với Hanas">
      <div className={styles.pinnedStage} ref={stageRef}>
        <div className={styles.atmosphere} aria-hidden="true" />

        <div className={`container ${styles.stageLayout}`}>
          <div className={styles.storyColumn}>
            <span className={styles.sectionEyebrow}>Từ phân tán đến tin cậy</span>

            <div className={styles.chapterStack}>
              {chapters.map((chapter, index) => (
                <article
                  className={`${styles.chapter} ${index === activeStage ? styles.chapterActive : ''}`}
                  key={chapter.eyebrow}
                >
                  <span className={styles.chapterNumber}>{String(index + 1).padStart(2, '0')}</span>
                  <span className={styles.chapterEyebrow}>{chapter.eyebrow}</span>
                  <h2>{chapter.title}</h2>
                  <p>{chapter.description}</p>
                  <span className={styles.chapterOutcome}>{chapter.outcome}</span>
                  <MobileRecordEvidence stage={index} />
                </article>
              ))}
            </div>

            <div className={styles.scrollCue} aria-hidden="true">
              <span />
              Cuộn để đưa dữ liệu đi tiếp
            </div>
          </div>

          <div className={styles.visualStage}>
            <div className={styles.canvasLayer} ref={canvasLayerRef}>
              {enhancedStory ? (
                <StoryCanvasBoundary>
                  <Suspense fallback={<div className={styles.canvasLoader} aria-hidden="true"><span /></div>}>
                    <JourneyCanvas progressRef={progressRef} />
                  </Suspense>
                </StoryCanvasBoundary>
              ) : null}
            </div>

            <div className={styles.visualLabel} aria-hidden="true">
              <span>HANAS / LUỒNG DỮ LIỆU</span>
              <strong>{String(activeStage + 1).padStart(2, '0')}</strong>
            </div>

            <RecordStoryOverlay activeStage={activeStage} qualityPhase={qualityPhase} />

            <div className={styles.dashboardWrap} ref={dashboardRef}>
              <DashboardPanel />
            </div>
          </div>
        </div>

        <div className={styles.progressRail} aria-label={`Bước ${activeStage + 1} trên ${chapters.length}`}>
          <span className={styles.progressRunway} aria-hidden="true" />
          <div className={styles.progressSteps}>
            {chapterLabels.map((label, index) => (
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
