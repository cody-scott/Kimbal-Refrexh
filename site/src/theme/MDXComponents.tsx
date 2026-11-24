// Make the lesson components available in every .md/.mdx file without imports.
import MDXComponents from '@theme-original/MDXComponents';
import KimballRef from '@site/src/components/KimballRef';
import Quiz from '@site/src/components/Quiz';
import DbtFile from '@site/src/components/DbtFile';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

export default {
  ...MDXComponents,
  KimballRef,
  Quiz,
  DbtFile,
  Tabs,
  TabItem,
};
