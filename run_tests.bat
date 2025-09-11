@echo off
echo ========================================
echo    تشغيل اختبارات نظام إدارة المكتب
echo ========================================
echo.

echo [1/6] تشغيل اختبارات قاعدة البيانات...
flutter test test/database/ --reporter=expanded
echo.

echo [2/6] تشغيل اختبارات واجهة المستخدم...
flutter test test/widgets/ --reporter=expanded
echo.

echo [3/6] تشغيل اختبارات الوحدات...
flutter test test/unit/ --reporter=expanded
echo.

echo [4/6] تشغيل اختبارات الخدمات...
flutter test test/services/ --reporter=expanded
echo.

echo [5/6] تشغيل اختبارات التكامل...
flutter test test/integration/ --reporter=expanded
echo.

echo [6/6] تشغيل اختبارات الأداء...
flutter test test/performance/ --reporter=expanded
echo.

echo ========================================
echo    تشغيل جميع الاختبارات
echo ========================================
flutter test --reporter=expanded

echo.
echo ========================================
echo    تم الانتهاء من جميع الاختبارات
echo ========================================
pause
