import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/domain/domains.dart';

void main() {
  test('四个默认领域、顺序固定', () {
    expect(kDefaultDomains, ['工作', '自媒体', '学习', '家庭']);
  });

  test('isCustomDomain：非空且不在默认集合里才算自定义', () {
    expect(isCustomDomain('工作'), false);
    expect(isCustomDomain('副业'), true);
    expect(isCustomDomain(null), false);
    expect(isCustomDomain(''), false);
    expect(isCustomDomain('  '), false);
  });
}
