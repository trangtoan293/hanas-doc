import {useEffect, useRef} from 'react';

// ponytail: HTML không có lazy-loading cho <video> như <img loading="lazy">.
// autoPlay khiến trình duyệt tải hết mọi video của trang ngay từ đầu, nên thay
// bằng: preload="none" + chỉ play khi video vào gần viewport, pause khi ra khỏi.
export default function useLazyVideo(deps: unknown[] = []) {
  const ref = useRef<HTMLVideoElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    // Không có IntersectionObserver (trình duyệt cũ) → phát luôn như trước.
    if (typeof IntersectionObserver === 'undefined') {
      el.preload = 'auto';
      el.play().catch(() => {});
      return;
    }

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          el.preload = 'auto';
          el.play().catch(() => {}); // autoplay bị chặn → giữ nguyên poster
        } else {
          el.pause();
        }
      },
      {rootMargin: '300px'}, // tải sớm một chút trước khi người dùng cuộn tới
    );

    observer.observe(el);
    return () => observer.disconnect();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  return ref;
}

// Poster lấy từ chính frame của video (static/img/poster/<tên video>.webp), nên
// mỗi section có ảnh chờ riêng và không "nhảy hình" khi video bắt đầu chạy.
export function posterOf(video: string): string {
  return video.replace('/video/', '/img/poster/').replace(/\.mp4$/, '.webp');
}
