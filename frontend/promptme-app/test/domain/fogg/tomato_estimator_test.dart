import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/fogg/tomato_estimator.dart';

void main() {
  group('TomatoEstimator.local', () {
    test('小事词 → 1', () {
      expect(TomatoEstimator.local('回复邮件'), 1);
      expect(TomatoEstimator.local('打卡'), 1);
    });
    test('大任务词 → 3', () {
      expect(TomatoEstimator.local('写项目周报'), 3);
      expect(TomatoEstimator.local('复习线性代数'), 3);
    });
    test('普通 → 2', () {
      expect(TomatoEstimator.local('整理桌面'), 2);
    });
    test('空标题 → 2', () {
      expect(TomatoEstimator.local('   '), 2);
    });
    test('大任务 + 超长标题 → 4（封顶）', () {
      expect(
          TomatoEstimator.local('写一份非常详尽的年度项目复盘总结报告文档初稿'), 4);
    });
  });

  group('TomatoEstimator.parseOrLocal', () {
    test('抽出首个 1–4 整数', () {
      expect(TomatoEstimator.parseOrLocal('大概 3 个番茄', '写报告'), 3);
      expect(TomatoEstimator.parseOrLocal('2', '任意'), 2);
    });
    test('越界数字按本地兜底（无 1–4 命中）', () {
      // '9' 不在 1–4，正则无命中 → 本地：'打卡'=1
      expect(TomatoEstimator.parseOrLocal('9', '打卡'), 1);
    });
    test('无数字 → 本地兜底', () {
      expect(TomatoEstimator.parseOrLocal('不知道', '写方案'), 3);
    });
  });
}
