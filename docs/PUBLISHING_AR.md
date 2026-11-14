# خطوات نشر التعريف

## 1. النشر على GitHub

1. أنشئ حسابًا على github.com إن لم يكن عندك.
2. من الموقع اضغط **New repository**، وسمّه `hiti-p630c-linux`، واجعله **Public** بدون README.
3. على جهازك، داخل مجلد المشروع:

```bash
cd hiti-p630c-linux
git init
git add .
git commit -m "HiTi P630C Linux driver installer"
git branch -M main
git remote add origin https://github.com/اسم_حسابك/hiti-p630c-linux.git
git push -u origin main
```

GitHub يطلب **Personal Access Token** بدل كلمة المرور عند `push`
(Settings → Developer settings → Personal access tokens).
أو ثبّت أداة GitHub الرسمية ونفّذ:

```bash
sudo apt install gh
gh auth login
gh repo create hiti-p630c-linux --public --source . --push
```

4. أنشئ إصدارًا قابلًا للتنزيل:

```bash
gh release create v1.0 --title "HiTi P630C Linux v1.0" --notes "First release. Tested on Ubuntu 24.04 with Gutenprint 5.3.6."
```

**مهم:** لا ترفع ملفات `.bin` ولا ملف `P630_Driver.zip`. هذه الملفات ملك لشركة HiTi،
وملف `.gitignore` يمنع رفعها تلقائيًا. تأكد قبل `push` بالأمر:

```bash
git ls-files | grep -E "\.bin|\.zip" || echo "OK - لا توجد ملفات HiTi"
```

## 2. إرسال التعديل لمطوّري Gutenprint (ليصبح رسميًا)

1. ادخل إلى صفحة مشروع Gutenprint على SourceForge (gimp-print)، وسجّل حسابًا.
2. افتح تذكرة جديدة في **Support Requests** أو **Patches**.
3. انسخ العنوان والنص من `docs/UPSTREAM_REPORT.md`.
4. أرفق ملف `patches/0001-hiti-p630c-usb-id.patch`.

لا تضع الرقم التسلسلي للطابعة في أي بلاغ عام.

## 3. النشر في المنتديات (اختياري)

- Ask Ubuntu أو منتدى Ubuntu: موضوع بعنوان "HiTi P630C on Linux" مع رابط GitHub.
- مجموعات أصحاب أكشاك التصوير (Photo booth) على فيسبوك وReddit.
