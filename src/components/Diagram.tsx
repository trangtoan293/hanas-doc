import type {ReactNode} from 'react';
import ThemedImage from '@theme/ThemedImage';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';

type Props = {
  /** File name without extension, shared by static/diagrams/<locale>/ and static/img/diagrams/<locale>/. */
  name: string;
  alt: string;
};

// Preview image (follows the site color mode) linking to the interactive diagram for the current locale.
export default function Diagram({name, alt}: Props): ReactNode {
  const {i18n} = useDocusaurusContext();
  const locale = i18n.currentLocale === 'en' ? 'en' : 'vi';
  const href = useBaseUrl(`/diagrams/${locale}/${name}.html`);
  const light = useBaseUrl(`/img/diagrams/${locale}/${name}-light.webp`);
  const dark = useBaseUrl(`/img/diagrams/${locale}/${name}-dark.webp`);
  const open = locale === 'en' ? 'Open the interactive diagram' : 'Mở sơ đồ tương tác';

  return (
    <figure className="hanas-diagram">
      <a href={href} target="_blank" rel="noopener" aria-label={`${alt} — ${open}`}>
        <ThemedImage alt={alt} sources={{light, dark}} />
      </a>
      <figcaption>
        {alt} ·{' '}
        <a href={href} target="_blank" rel="noopener">
          {open} ↗
        </a>
      </figcaption>
    </figure>
  );
}
