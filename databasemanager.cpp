#include "databasemanager.h"

DatabaseManager::DatabaseManager(QObject *parent) : QObject(parent) {}

DatabaseManager::~DatabaseManager() {
    if (m_db.isOpen()) m_db.close();
}

bool DatabaseManager::initDatabase() {
    QString dbPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir;
    if (!dir.exists(dbPath)) dir.mkpath(dbPath);

    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(dbPath + "/appmusleh.db");

    if (!m_db.open()) return false;
    createTables();
    return true;
}

void DatabaseManager::createTables() {
    QSqlQuery query;
    query.exec("CREATE TABLE IF NOT EXISTS students (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE NOT NULL)");
    query.exec("CREATE TABLE IF NOT EXISTS attendance ("
               "id INTEGER PRIMARY KEY AUTOINCREMENT, student_id INTEGER, session_date TEXT, "
               "arrival_time TEXT, fine_amount REAL DEFAULT 0, is_paid INTEGER DEFAULT 0, "
               "not_late INTEGER DEFAULT 0, is_present INTEGER DEFAULT 0)");
    query.exec("CREATE TABLE IF NOT EXISTS assignments (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, assign_date TEXT, teacher_name TEXT)");
    query.exec("CREATE TABLE IF NOT EXISTS student_assignments ("
               "assignment_id INTEGER, student_id INTEGER, is_completed INTEGER DEFAULT 0, "
               "PRIMARY KEY(assignment_id, student_id))");
}

bool DatabaseManager::addStudent(const QString &name) {
    if (name.trimmed().isEmpty()) return false;
    QSqlQuery query;
    query.prepare("INSERT INTO students (name) VALUES (:name)");
    query.bindValue(":name", name.trimmed());
    return query.exec();
}

bool DatabaseManager::deleteStudent(int studentId) {
    m_db.transaction();
    QSqlQuery q;
    q.prepare("DELETE FROM attendance WHERE student_id = :id"); q.bindValue(":id", studentId); q.exec();
    q.prepare("DELETE FROM student_assignments WHERE student_id = :id"); q.bindValue(":id", studentId); q.exec();
    q.prepare("DELETE FROM students WHERE id = :id"); q.bindValue(":id", studentId);
    if (q.exec()) return m_db.commit();
    m_db.rollback();
    return false;
}

QVariantList DatabaseManager::getStudentsSorted() {
    QVariantList studentList;
    QSqlQuery query("SELECT id, name FROM students ORDER BY name ASC");
    while (query.next()) {
        QVariantMap student;
        student["id"] = query.value(0).toInt();
        student["name"] = query.value(1).toString();
        studentList.append(student);
    }
    return studentList;
}

bool DatabaseManager::saveAttendanceSession(const QVariantList &sessionData) {
    m_db.transaction();
    QSqlQuery query;
    for (const QVariant &item : sessionData) {
        QVariantMap map = item.toMap();
        query.prepare("INSERT INTO attendance (student_id, session_date, arrival_time, fine_amount, not_late, is_present) "
                      "VALUES (:student_id, :date, :time, :fine, :not_late, :is_present)");
        query.bindValue(":student_id", map["studentId"].toInt());
        query.bindValue(":date", map["date"].toString());
        query.bindValue(":time", map["time"].toString());
        query.bindValue(":fine", map["fine"].toDouble());
        query.bindValue(":not_late", map["notLate"].toBool() ? 1 : 0);
        query.bindValue(":is_present", map["isPresent"].toBool() ? 1 : 0);
        if (!query.exec()) { m_db.rollback(); return false; }
    }
    return m_db.commit();
}

bool DatabaseManager::addAssignment(const QString &title, const QString &teacherName) {
    if (title.trimmed().isEmpty()) return false;
    QSqlQuery query;
    query.prepare("INSERT INTO assignments (title, assign_date, teacher_name) VALUES (:title, :date, :teacher)");
    query.bindValue(":title", title.trimmed());
    query.bindValue(":date", QDate::currentDate().toString("yyyy-MM-dd"));
    query.bindValue(":teacher", teacherName.trimmed());
    return query.exec();
}

QVariantList DatabaseManager::getAssignments() {
    QVariantList list;
    QSqlQuery query("SELECT id, title, assign_date, teacher_name FROM assignments ORDER BY id DESC");
    while (query.next()) {
        QVariantMap map;
        map["id"] = query.value(0).toInt();
        map["title"] = query.value(1).toString();
        map["date"] = query.value(2).toString();
        map["teacher"] = query.value(3).toString();
        list.append(map);
    }
    return list;
}

QVariantList DatabaseManager::getAssignmentStudents(int assignmentId) {
    QVariantList list;
    QSqlQuery query;
    query.prepare("SELECT s.id, s.name, COALESCE(sa.is_completed, 0) FROM students s "
                  "LEFT JOIN student_assignments sa ON s.id = sa.student_id AND sa.assignment_id = :aid "
                  "ORDER BY s.name ASC");
    query.bindValue(":aid", assignmentId);
    query.exec();
    while (query.next()) {
        QVariantMap map;
        map["studentId"] = query.value(0).toInt();
        map["name"] = query.value(1).toString();
        map["isCompleted"] = query.value(2).toInt() == 1;
        list.append(map);
    }
    return list;
}

bool DatabaseManager::saveAssignmentStatus(int assignmentId, const QVariantList &statusData) {
    m_db.transaction();
    QSqlQuery query;
    for (const QVariant &item : statusData) {
        QVariantMap map = item.toMap();
        query.prepare("INSERT OR REPLACE INTO student_assignments (assignment_id, student_id, is_completed) "
                      "VALUES (:aid, :sid, :status)");
        query.bindValue(":aid", assignmentId);
        query.bindValue(":sid", map["studentId"].toInt());
        query.bindValue(":status", map["isCompleted"].toBool() ? 1 : 0);
        if (!query.exec()) { m_db.rollback(); return false; }
    }
    return m_db.commit();
}

QVariantList DatabaseManager::getAttendanceSummary() {
    QVariantList list;
    QSqlQuery query(
        "SELECT s.name, "
        "SUM(a.is_present) as present_days, "
        "SUM(CASE WHEN a.is_present = 0 THEN 1 ELSE 0 END) as absent_days, "
        "SUM(CASE WHEN a.is_present = 1 AND a.not_late = 0 THEN 1 ELSE 0 END) as late_days "
        "FROM students s LEFT JOIN attendance a ON s.id = a.student_id "
        "GROUP BY s.id ORDER BY s.name ASC"
        );
    while (query.next()) {
        QVariantMap map;
        map["name"] = query.value(0).toString();
        map["present"] = query.value(1).toInt();
        map["absent"] = query.value(2).toInt();
        map["late"] = query.value(3).toInt();
        list.append(map);
    }
    return list;
}

QVariantMap DatabaseManager::getStudentAssignmentSummary(int studentId) {
    QVariantMap map;
    QSqlQuery query;
    query.prepare("SELECT "
                  "SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as done, "
                  "SUM(CASE WHEN is_completed = 0 THEN 1 ELSE 0 END) as not_done "
                  "FROM student_assignments WHERE student_id = :sid");
    query.bindValue(":sid", studentId);
    query.exec();
    if (query.next()) {
        map["done"] = query.value(0).toInt();
        map["notDone"] = query.value(1).toInt();
    }
    return map;
}

QVariantList DatabaseManager::getFinesSummary() {
    QVariantList list;
    QSqlQuery query(
        "SELECT s.id, s.name, "
        "COALESCE(SUM(CASE WHEN a.is_paid = 1 THEN a.fine_amount ELSE 0 END), 0) as paid, "
        "COALESCE(SUM(CASE WHEN a.is_paid = 0 THEN a.fine_amount ELSE 0 END), 0) as unpaid, "
        "COALESCE(SUM(a.fine_amount), 0) as total "
        "FROM students s LEFT JOIN attendance a ON s.id = a.student_id "
        "GROUP BY s.id ORDER BY s.name ASC"
        );
    while (query.next()) {
        QVariantMap map;
        map["id"] = query.value(0).toInt();
        map["name"] = query.value(1).toString();
        map["paid"] = query.value(2).toDouble();
        map["unpaid"] = query.value(3).toDouble();
        map["total"] = query.value(4).toDouble();
        list.append(map);
    }
    return list;
}

QVariantList DatabaseManager::getStudentFinesDetail(int studentId) {
    QVariantList list;
    QSqlQuery query;
    query.prepare("SELECT id, session_date, fine_amount, is_paid FROM attendance "
                  "WHERE student_id = :sid AND fine_amount > 0 ORDER BY id DESC");
    query.bindValue(":sid", studentId);
    query.exec();
    while (query.next()) {
        QVariantMap map;
        map["attendanceId"] = query.value(0).toInt();
        map["date"] = query.value(1).toString();
        map["amount"] = query.value(2).toDouble();
        map["isPaid"] = query.value(3).toInt() == 1;
        list.append(map);
    }
    return list;
}

bool DatabaseManager::markFineAsPaid(int attendanceId) {
    QSqlQuery query;
    query.prepare("UPDATE attendance SET is_paid = 1 WHERE id = :id");
    query.bindValue(":id", attendanceId);
    return query.exec();
}

// الإعفاء يصفر قيمة الغرامة في قاعدة البيانات
bool DatabaseManager::waiveFine(int attendanceId) {
    QSqlQuery query;
    query.prepare("UPDATE attendance SET fine_amount = 0, is_paid = 0 WHERE id = :id");
    query.bindValue(":id", attendanceId);
    return query.exec();
}