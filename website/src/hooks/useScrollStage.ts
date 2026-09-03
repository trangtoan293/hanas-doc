import {useEffect, useState} from 'react';
import {ScrollTrigger} from 'gsap/ScrollTrigger';

/**
 * Các khối kể chuyện theo scroll chỉ chạy trên desktop và khi người dùng không
 * yêu cầu giảm chuyển động; mobile dùng bản tĩnh xếp dọc.
 */
export function useDesktopMotion(): boolean {
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

/** --ifm-navbar-height là clamp() nên parseFloat trả NaN — đo thẳng phần tử navbar. */
export function getNavbarHeight(): number {
  const navbar = document.querySelector('.navbar');
  return navbar ? navbar.getBoundingClientRect().height : 0;
}

/**
 * ScrollTrigger được tạo sau hydrate, thường muộn hơn sự kiện `load`, nên nó không
 * tự đo lại: pin-spacer giữ chiều dài 0 và cả khối trôi tuột. Gọi hàm này sau khi
 * dựng trigger, và chạy hàm dọn trả về trong cleanup.
 */
export function scheduleScrollTriggerRefresh(): () => void {
  const refresh = () => ScrollTrigger.refresh();
  const frame = requestAnimationFrame(refresh);
  document.fonts?.ready.then(refresh);
  return () => cancelAnimationFrame(frame);
}
