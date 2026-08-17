#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QVariantList>
#include <QVariantMap>
#include <QDate>
#include <QDebug>

class DatabaseManager : public QObject
{
    Q_OBJECT
public:
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();

    Q_INVOKABLE bool initDatabase();
    Q_INVOKABLE bool addStudent(const QString &name);
    Q_INVOKABLE bool deleteStudent(int studentId);
    Q_INVOKABLE QVariantList getStudentsSorted();
    Q_INVOKABLE bool saveAttendanceSession(const QVariantList &sessionData);

    Q_INVOKABLE bool addAssignment(const QString &title, const QString &teacherName);
    Q_INVOKABLE QVariantList getAssignments();
    Q_INVOKABLE QVariantList getAssignmentStudents(int assignmentId);
    Q_INVOKABLE bool saveAssignmentStatus(int assignmentId, const QVariantList &statusData);

    Q_INVOKABLE QVariantList getAttendanceSummary();
    Q_INVOKABLE QVariantMap getStudentAssignmentSummary(int studentId);

    Q_INVOKABLE QVariantList getFinesSummary();
    Q_INVOKABLE QVariantList getStudentFinesDetail(int studentId);
    Q_INVOKABLE bool markFineAsPaid(int attendanceId);
    Q_INVOKABLE bool waiveFine(int attendanceId); // دالة الإعفاء من الغرامة

private:
    QSqlDatabase m_db;
    void createTables();
};

#endif // DATABASEMANAGER_H