import React, {type ReactNode} from 'react';
import {DWT3_CHAPTERS, KIMBALL_TECHNIQUES_URL} from '@site/src/data/kimball';
import styles from './styles.module.css';

type Props = {
  /** Chapter number(s) of The Data Warehouse Toolkit, 3rd ed. */
  chapters: number[];
  /** Technique names exactly as the Kimball Group lists them. */
  techniques?: string[];
  children?: ReactNode;
};

/** A "where this comes from in Kimball" callout shown near the top of a lesson. */
export default function KimballRef({chapters, techniques = [], children}: Props) {
  return (
    <aside className={styles.ref} aria-label="Kimball source">
      <div className={styles.label}>Kimball source</div>
      <ul className={styles.list}>
        {chapters.map((c) => (
          <li key={c}>
            <em>The Data Warehouse Toolkit</em> (3rd ed.), Ch. {c}: {DWT3_CHAPTERS[c] ?? 'Unknown chapter'}
          </li>
        ))}
      </ul>
      {techniques.length > 0 && (
        <div className={styles.techniques}>
          <a href={KIMBALL_TECHNIQUES_URL} target="_blank" rel="noopener noreferrer">
            Kimball techniques
          </a>
          :{' '}
          {techniques.map((t) => (
            <span key={t} className={styles.chip}>
              {t}
            </span>
          ))}
        </div>
      )}
      {children && <div className={styles.note}>{children}</div>}
    </aside>
  );
}
