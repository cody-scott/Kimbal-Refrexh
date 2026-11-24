import React, {useEffect, useState} from 'react';
import clsx from 'clsx';
import {isDone, onProgressChange, setDone} from './store';
import styles from './styles.module.css';

export default function LessonComplete({id}: {id: string}) {
  const [done, setLocal] = useState(false);
  useEffect(() => {
    const sync = () => setLocal(isDone(id));
    sync();
    return onProgressChange(sync);
  }, [id]);
  return (
    <div className={styles.complete}>
      <button
        type="button"
        className={clsx('button', done ? 'button--success' : 'button--outline button--primary')}
        onClick={() => setDone(id, !done)}>
        {done ? '✓ Lesson complete' : 'Mark lesson complete'}
      </button>
      <span className={styles.hint}>Saved in this browser only.</span>
    </div>
  );
}
