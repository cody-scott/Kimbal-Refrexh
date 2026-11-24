import React from 'react';
import Footer from '@theme-original/DocItem/Footer';
import type FooterType from '@theme/DocItem/Footer';
import type {WrapperProps} from '@docusaurus/types';
import {useDoc} from '@docusaurus/plugin-content-docs/client';
import LessonComplete from '@site/src/components/Progress/LessonComplete';

type Props = WrapperProps<typeof FooterType>;

// Adds a "Mark lesson complete" button to every lesson page
// (skipped on pages that set `hide_progress: true` in front matter).
export default function FooterWrapper(props: Props) {
  const {metadata, frontMatter} = useDoc();
  const hide = (frontMatter as {hide_progress?: boolean}).hide_progress;
  return (
    <>
      {!hide && <LessonComplete id={metadata.id} />}
      <Footer {...props} />
    </>
  );
}
