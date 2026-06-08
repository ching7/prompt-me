import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/theme/app_colors.dart';

void main() {
  test('四个默认领域映射到固定色，未分类/自定义回退 ink40', () {
    expect(AppColors.domainColor('工作'), AppColors.q1);
    expect(AppColors.domainColor('自媒体'), AppColors.q3);
    expect(AppColors.domainColor('学习'), AppColors.q2);
    expect(AppColors.domainColor('家庭'), AppColors.q4);
    expect(AppColors.domainColor(null), AppColors.ink40);
    expect(AppColors.domainColor('副业'), AppColors.ink40); // 自定义
    expect(AppColors.domainTint('工作'), AppColors.q1Tint);
    expect(AppColors.domainTint(null), AppColors.ink20);
  });
}
