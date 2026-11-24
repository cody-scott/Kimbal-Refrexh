// Lesson progress lives in the reader's own browser (localStorage).
// Every access is wrapped: storage can be unavailable (private mode, SSR).
const PREFIX = 'kimball-refresh:done:';
const EVENT = 'kimball-refresh:progress';

export function isDone(id: string): boolean {
  try {
    return window.localStorage.getItem(PREFIX + id) === '1';
  } catch {
    return false;
  }
}

export function setDone(id: string, done: boolean): void {
  try {
    if (done) window.localStorage.setItem(PREFIX + id, '1');
    else window.localStorage.removeItem(PREFIX + id);
    window.dispatchEvent(new Event(EVENT));
  } catch {
    /* storage unavailable: progress just isn't remembered */
  }
}

export function onProgressChange(cb: () => void): () => void {
  window.addEventListener(EVENT, cb);
  window.addEventListener('storage', cb);
  return () => {
    window.removeEventListener(EVENT, cb);
    window.removeEventListener('storage', cb);
  };
}
