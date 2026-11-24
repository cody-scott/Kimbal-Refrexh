import React, {useState} from 'react';
import clsx from 'clsx';
import styles from './styles.module.css';

export type QuizQuestion = {
  question: string;
  options: string[];
  /** Index of the correct option. */
  answer: number;
  explanation: string;
};

function Question({q, index}: {q: QuizQuestion; index: number}) {
  const [picked, setPicked] = useState<number | null>(null);
  const answered = picked !== null;
  return (
    <div className={styles.question}>
      <p className={styles.prompt}>
        <strong>Q{index + 1}.</strong> {q.question}
      </p>
      <div className={styles.options} role="radiogroup">
        {q.options.map((opt, i) => (
          <button
            key={i}
            type="button"
            role="radio"
            aria-checked={picked === i}
            className={clsx(
              styles.option,
              answered && i === q.answer && styles.correct,
              answered && picked === i && i !== q.answer && styles.wrong,
            )}
            onClick={() => setPicked(i)}>
            <span className={styles.letter}>{String.fromCharCode(65 + i)}</span>
            <span>{opt}</span>
          </button>
        ))}
      </div>
      {answered && (
        <div className={clsx(styles.feedback, picked === q.answer ? styles.fbGood : styles.fbBad)}>
          <strong>{picked === q.answer ? 'Correct.' : `Not quite. The answer is ${String.fromCharCode(65 + q.answer)}.`}</strong>{' '}
          {q.explanation}
          <button type="button" className={styles.retry} onClick={() => setPicked(null)}>
            Try again
          </button>
        </div>
      )}
    </div>
  );
}

/** A self-check quiz. Nothing is stored; it's for retrieval practice. */
export default function Quiz({title = 'Check your understanding', questions}: {title?: string; questions: QuizQuestion[]}) {
  return (
    <section className={styles.quiz}>
      <h3 className={styles.title}>{title}</h3>
      {questions.map((q, i) => (
        <Question key={i} q={q} index={i} />
      ))}
    </section>
  );
}
