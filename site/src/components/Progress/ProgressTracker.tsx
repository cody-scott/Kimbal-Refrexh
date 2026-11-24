import React, {useEffect, useState} from 'react';
import Link from '@docusaurus/Link';
import {useAllDocsData} from '@docusaurus/plugin-content-docs/client';
import {isDone, onProgressChange} from './store';
import styles from './styles.module.css';

const MODULES: {prefix: string; label: string}[] = [
  {prefix: 'foundations/', label: '0 · Foundations'},
  {prefix: 'facts/', label: '1 · Fact tables'},
  {prefix: 'dimensions/', label: '2 · Dimension tables'},
  {prefix: 'scd/', label: '3 · Slowly changing dimensions'},
  {prefix: 'advanced/', label: '4 · Advanced patterns'},
  {prefix: 'bus/', label: '5 · Enterprise bus'},
  {prefix: 'dbt/', label: '6 · Kimball in dbt'},
  {prefix: 'case-studies/', label: '7 · Case studies'},
  {prefix: 'practice/', label: '8 · Practice'},
];

export default function ProgressTracker() {
  const docs = useAllDocsData()['default'].versions[0].docs;
  const [, force] = useState(0);
  useEffect(() => onProgressChange(() => force((n) => n + 1)), []);
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  return (
    <div className={styles.tracker}>
      {MODULES.map((m) => {
        const lessons = docs.filter((d) => d.id.startsWith(m.prefix));
        const done = mounted ? lessons.filter((d) => isDone(d.id)).length : 0;
        const pct = lessons.length ? Math.round((done / lessons.length) * 100) : 0;
        const first = lessons.find((d) => d.id.endsWith('/index')) ?? lessons[0];
        return (
          <div key={m.prefix} className={styles.row}>
            <Link to={first?.path ?? '#'} className={styles.rowLabel}>
              {m.label}
            </Link>
            <div className={styles.bar} role="progressbar" aria-valuenow={pct} aria-valuemin={0} aria-valuemax={100}>
              <div className={styles.fill} style={{width: `${pct}%`}} />
            </div>
            <span className={styles.count}>
              {done}/{lessons.length}
            </span>
          </div>
        );
      })}
    </div>
  );
}
