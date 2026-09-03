import React, {useRef} from 'react';
import {useGSAP} from '@gsap/react';
import {gsap} from 'gsap';
import {ScrollTrigger} from 'gsap/ScrollTrigger';
import useLazyVideo from '@site/src/hooks/useLazyVideo';
import {
  getNavbarHeight,
  scheduleScrollTriggerRefresh,
  useDesktopMotion,
} from '@site/src/hooks/useScrollStage';
import styles from './styles.module.css';

if (typeof window !== 'undefined') {
  gsap.registerPlugin(useGSAP, ScrollTrigger);
}

export default function HeroSection(): React.JSX.Element {
  const videoRef = useLazyVideo();
  const heroRef = useRef<HTMLElement>(null);
  const contentRef = useRef<HTMLDivElement>(null);
  const desktopMotion = useDesktopMotion();

  useGSAP(
    () => {
      const hero = heroRef.current;
      const content = contentRef.current;
      if (!desktopMotion || !hero || !content) return;

      const ambient = hero.querySelectorAll<HTMLElement>('[data-hero-ambient]');

      // pinSpacing: false -> hero đứng yên còn chương kế tiếp trượt lên che nó, và
      // chiều cao trang không đổi. Trước đây hero cuộn đi cùng lúc chương 01 đi lên,
      // nên ở giữa chỉ thấy nửa dưới trống của hero cộng nửa trên trống của chương 01.
      gsap.timeline({
        defaults: {ease: 'none'},
        scrollTrigger: {
          end: () => `+=${hero.offsetHeight}`,
          invalidateOnRefresh: true,
          pin: true,
          pinSpacing: false,
          scrub: 0.4,
          start: () => `top top+=${getNavbarHeight()}`,
          trigger: hero,
        },
      })
        .to(content, {autoAlpha: 0.1, scale: 0.94, y: -52}, 0)
        .to(ambient, {opacity: 0.18}, 0);

      return scheduleScrollTriggerRefresh();
    },
    {dependencies: [desktopMotion], revertOnUpdate: true, scope: heroRef},
  );

  return (
    <section className={styles.hero} ref={heroRef}>
      <video
        className={styles.stageVideo}
        ref={videoRef}
        muted
        loop
        playsInline
        preload="none"
        poster="/img/poster/main-background.webp"
        aria-hidden="true"
        data-hero-ambient
      >
        <source src="/video/main-background.mp4" type="video/mp4" />
      </video>
      <div className={styles.gridBackdrop} aria-hidden="true" data-hero-ambient />
      <div className={styles.heroGlow} aria-hidden="true" data-hero-ambient />

      <div className={`container ${styles.heroContainer}`}>
        <div className={styles.heroInner}>
          <div className={styles.heroContent} ref={contentRef}>
            <span className={`${styles.heroEyebrow} ${styles.animateIn} ${styles.delay1}`}>
              Data &amp; AI Platform
            </span>

            <h1 className={`${styles.heroTitle} ${styles.animateIn} ${styles.delay2}`}>
              Kết nối mọi nguồn dữ liệu
              <span className={styles.gradientText}>cho phân tích và AI.</span>
            </h1>

            <p className={`${styles.heroSubtitle} ${styles.animateIn} ${styles.delay3}`}>
              Doanh nghiệp có một nguồn dữ liệu tin cậy cho BI, analytics và AI. Hanas
              thu thập và liên kết dữ liệu phân tán trong kiến trúc Lakehouse mở, có
              quản trị.
            </p>

            <div className={`${styles.trustRow} ${styles.animateIn} ${styles.delay4}`}>
              <span>Open formats</span>
              <span className={styles.trustDivider} aria-hidden="true">|</span>
              <span>On-premise</span>
              <span className={styles.trustDivider} aria-hidden="true">|</span>
              <span>Private cloud</span>
              <span className={styles.trustDivider} aria-hidden="true">|</span>
              <span>Hybrid</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
