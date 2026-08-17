import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: window
    width: 950
    height: 650
    visible: true
    title: qsTr("appmusleh")

    property color primaryColor: "#2C3E50"
    property color backgroundColor: "#F4F6F7"

    property int activeAssignmentId: -1
    property int activeStudentId: -1
    property int selectedStudentIdToDelete: -1
    property string activeStudentName: ""

    ListModel { id: studentsModel }
    ListModel { id: summaryModel }
    ListModel { id: finesModel }
    ListModel { id: assignmentsModel }
    ListModel { id: assignmentStudentsModel }
    ListModel { id: studentFinesDetailModel }

    function refreshStudents() {
        studentsModel.clear();
        if (typeof dbManager !== "undefined") {
            var list = dbManager.getStudentsSorted();
            for (var i = 0; i < list.length; i++) {
                studentsModel.append({ "studentId": list[i].id, "name": list[i].name, "date": "", "time": "", "fine": "", "notLate": false, "isPresent": false });
            }
        }
    }

    function refreshSummary() {
        summaryModel.clear();
        if (typeof dbManager !== "undefined") {
            var list = dbManager.getAttendanceSummary();
            for (var i = 0; i < list.length; i++) summaryModel.append(list[i]);
        }
    }

    function refreshFines() {
        finesModel.clear();
        if (typeof dbManager !== "undefined") {
            var list = dbManager.getFinesSummary();
            for (var i = 0; i < list.length; i++) finesModel.append(list[i]);
        }
    }

    function refreshAssignments() {
        assignmentsModel.clear();
        if (typeof dbManager !== "undefined") {
            var list = dbManager.getAssignments();
            for (var i = 0; i < list.length; i++) assignmentsModel.append(list[i]);
        }
    }

    function getCurrentDate() {
        var d = new Date();
        return d.getFullYear() + "-" + ("0" + (d.getMonth()+1)).slice(-2) + "-" + ("0" + d.getDate()).slice(-2);
    }

    function getCurrentTime() {
        var d = new Date();
        return ("0" + d.getHours()).slice(-2) + ":" + ("0" + d.getMinutes()).slice(-2);
    }

    Component.onCompleted: {
        refreshStudents();
        refreshFines();
    }

    Rectangle {
        anchors.fill: parent
        color: backgroundColor

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 50; color: primaryColor
                Text { anchors.centerIn: parent; text: "appmusleh"; color: "white"; font.pixelSize: 18; font.bold: true }
            }

            TabBar {
                id: mainTabBar
                Layout.fillWidth: true; currentIndex: 0
                onCurrentIndexChanged: {
                    if (currentIndex === 1) refreshSummary();
                    if (currentIndex === 2) refreshFines();
                }
                TabButton { text: "الصفحة الرئيسية" }
                TabButton { text: "المحصلات" }
                TabButton { text: "الغرامات" }
            }

            StackLayout {
                Layout.fillWidth: true; Layout.fillHeight: true; currentIndex: mainTabBar.currentIndex

                // 1. الصفحة الرئيسية
                Item {
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 8; spacing: 8
                        TabBar {
                            id: homeSubBar; Layout.fillWidth: true; currentIndex: 0
                            onCurrentIndexChanged: if (currentIndex === 1) refreshAssignments();
                            TabButton { text: "الالتزام" }
                            TabButton { text: "التكاليف العملية" }
                        }
                        StackLayout {
                            Layout.fillWidth: true; Layout.fillHeight: true; currentIndex: homeSubBar.currentIndex

                            // الالتزام
                            Item {
                                ColumnLayout {
                                    anchors.fill: parent; spacing: 8
                                    Button { text: "+ إنشاء طالب جديد"; Layout.alignment: Qt.AlignHCenter; onClicked: addStudentDialog.open() }

                                    Rectangle {
                                        Layout.fillWidth: true; Layout.preferredHeight: 35; color: "#34495E"; radius: 3
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 5; spacing: 2
                                            Text { text: "حضور"; color: "white"; font.bold: true; Layout.preferredWidth: 45; horizontalAlignment: Text.AlignHCenter }
                                            Text { text: "اسم الطالب"; color: "white"; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                                            Text { text: "التاريخ"; color: "white"; font.bold: true; Layout.preferredWidth: 90; horizontalAlignment: Text.AlignHCenter }
                                            Text { text: "الوقت"; color: "white"; font.bold: true; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
                                            Text { text: "المبلغ"; color: "white"; font.bold: true; Layout.preferredWidth: 70; horizontalAlignment: Text.AlignHCenter }
                                            Text { text: "لم يتأخر"; color: "white"; font.bold: true; Layout.preferredWidth: 55; horizontalAlignment: Text.AlignHCenter }
                                            Text { text: "إجراء"; color: "white"; font.bold: true; Layout.preferredWidth: 60; horizontalAlignment: Text.AlignHCenter }
                                        }
                                    }

                                    ListView {
                                        id: studentListView; Layout.fillWidth: true; Layout.fillHeight: true; spacing: 4; model: studentsModel; clip: true
                                        delegate: Rectangle {
                                            width: studentListView.width; height: 45; color: "white"; border.color: "#BDC3C7"; radius: 4
                                            RowLayout {
                                                anchors.fill: parent; anchors.margins: 4
                                                CheckBox {
                                                    checked: model.isPresent;
                                                    onClicked: {
                                                        studentsModel.setProperty(index, "isPresent", checked);
                                                        if (checked) {
                                                            if (!model.date) studentsModel.setProperty(index, "date", getCurrentDate());
                                                            if (!model.time) studentsModel.setProperty(index, "time", getCurrentTime());
                                                        }
                                                    }
                                                }
                                                Text { text: model.name; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                                                TextField { text: model.date; placeholderText: "التاريخ"; Layout.preferredWidth: 90; onTextChanged: studentsModel.setProperty(index, "date", text) }
                                                TextField { text: model.time; placeholderText: "الوقت"; Layout.preferredWidth: 70; onTextChanged: studentsModel.setProperty(index, "time", text) }
                                                TextField { text: model.fine; placeholderText: "المبلغ"; enabled: !model.notLate; Layout.preferredWidth: 70; onTextChanged: studentsModel.setProperty(index, "fine", text) }
                                                CheckBox { checked: model.notLate; onClicked: { studentsModel.setProperty(index, "notLate", checked); if (checked) studentsModel.setProperty(index, "fine", "0"); } }
                                                Button {
                                                    text: "فصل"; palette.button: "#E74C3C"; palette.buttonText: "white"
                                                    onClicked: {
                                                        selectedStudentIdToDelete = model.studentId;
                                                        confirmDeleteDialog.open();
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    Button {
                                        text: "يوم جديد"; Layout.fillWidth: true; highlighted: true
                                        onClicked: {
                                            var isValid = true;
                                            var data = [];
                                            for (var i = 0; i < studentsModel.count; i++) {
                                                var it = studentsModel.get(i);
                                                if (it.isPresent) {
                                                    if (!it.date.trim() || !it.time.trim()) { isValid = false; break; }
                                                    if (!it.notLate && (!it.fine || it.fine.trim() === "")) { isValid = false; break; }
                                                }
                                                data.push({ "studentId": it.studentId, "date": it.date, "time": it.time, "fine": parseFloat(it.fine || 0), "notLate": it.notLate, "isPresent": it.isPresent });
                                            }

                                            if (!isValid) {
                                                warningDialog.open();
                                            } else {
                                                if (dbManager.saveAttendanceSession(data)) {
                                                    refreshStudents();
                                                    refreshFines();
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // التكاليف
                            Item {
                                ColumnLayout {
                                    anchors.fill: parent; spacing: 8
                                    Button { text: "+ إنشاء تكليف عملي"; Layout.alignment: Qt.AlignHCenter; onClicked: addAssignmentDialog.open() }
                                    ListView {
                                        Layout.fillWidth: true; Layout.fillHeight: true; model: assignmentsModel; clip: true
                                        delegate: Rectangle {
                                            width: parent.width; height: 50; color: "white"; border.color: "#3498DB"; radius: 4
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    activeAssignmentId = model.id;
                                                    assignmentStudentsModel.clear();
                                                    var list = dbManager.getAssignmentStudents(model.id);
                                                    for (var i = 0; i < list.length; i++) assignmentStudentsModel.append(list[i]);
                                                    manageAssignmentDialog.open();
                                                }
                                            }
                                            RowLayout {
                                                anchors.fill: parent; anchors.margins: 8
                                                Text { text: model.title; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                                                Text { text: "الأستاذ: " + model.teacher; color: "#7F8C8D" }
                                                Text { text: model.date; color: "#95A5A6" }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 2. المحصلات
                Item {
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 8; spacing: 8
                        TabBar {
                            id: summarySubBar; Layout.fillWidth: true; currentIndex: 0
                            TabButton { text: "الالتزام" }
                            TabButton { text: "التكاليف العملية" }
                        }
                        StackLayout {
                            Layout.fillWidth: true; Layout.fillHeight: true; currentIndex: summarySubBar.currentIndex

                            // محصلة الالتزام
                            ListView {
                                model: summaryModel; clip: true
                                delegate: Rectangle {
                                    width: parent.width; height: 45; color: "white"; border.color: "#BDC3C7"; radius: 4
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 8
                                        Text { text: model.name; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                                        Text { text: "حضور: " + model.present; color: "#27AE60" }
                                        Text { text: "غياب: " + model.absent; color: "#C0392B" }
                                        Text { text: "تأخير: " + model.late; color: "#E67E22" }
                                    }
                                }
                            }

                            // محصلة التكاليف
                            ListView {
                                model: studentsModel; clip: true
                                delegate: Rectangle {
                                    width: parent.width; height: 45; color: "white"; border.color: "#BDC3C7"; radius: 4
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            var res = dbManager.getStudentAssignmentSummary(model.studentId);
                                            studentTaskStatText.text = "الطالب: " + model.name + "\n\nعدد التكاليف المنجزة: " + (res.done || 0) + "\nعدد التكاليف غير المنجزة: " + (res.notDone || 0);
                                            studentTaskStatDialog.open();
                                        }
                                    }
                                    Text { anchors.centerIn: parent; text: model.name; font.bold: true; font.pixelSize: 15 }
                                }
                            }
                        }
                    }
                }

                // 3. الغرامات
                Item {
                    Component.onCompleted: refreshFines()

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 10
                        ListView {
                            id: finesListView
                            Layout.fillWidth: true; Layout.fillHeight: true; model: finesModel; clip: true
                            delegate: Rectangle {
                                width: finesListView.width; height: 65; color: "white"; border.color: "#BDC3C7"; radius: 5
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        activeStudentId = model.id;
                                        activeStudentName = model.name;
                                        refreshStudentFinesDetail();
                                        studentFinesDialog.open();
                                    }
                                }
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 10
                                    ColumnLayout {
                                        spacing: 2
                                        Text { text: "المتبقي: " + model.unpaid + " $"; color: "#C0392B"; font.bold: true }
                                        Text { text: "المدفوع: " + model.paid + " $"; color: "#27AE60" }
                                        Text { text: "الإجمالي: " + model.total + " $"; color: "#7F8C8D"; font.pixelSize: 11 }
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text { text: model.name; font.bold: true; font.pixelSize: 16; color: "#2C3E50"; horizontalAlignment: Text.AlignRight }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function refreshStudentFinesDetail() {
        studentFinesDetailModel.clear();
        var list = dbManager.getStudentFinesDetail(activeStudentId);
        for (var i = 0; i < list.length; i++) studentFinesDetailModel.append(list[i]);
    }

    // النوافذ المنبثقة
    Dialog {
        id: confirmDeleteDialog; title: "تأكيد الفصل"; anchors.centerIn: parent; modal: true; width: 320
        ColumnLayout {
            anchors.fill: parent; spacing: 10
            Text { text: "هل أنت الأستاذ متأكد من فصل هذا الطالب وحذفه؟"; wrapMode: Text.WordWrap; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
            RowLayout {
                Button { text: "إلغاء"; Layout.fillWidth: true; onClicked: confirmDeleteDialog.close() }
                Button {
                    text: "موافق"; highlighted: true; Layout.fillWidth: true
                    onClicked: {
                        dbManager.deleteStudent(selectedStudentIdToDelete);
                        refreshStudents();
                        refreshFines();
                        confirmDeleteDialog.close();
                    }
                }
            }
        }
    }

    Dialog {
        id: warningDialog; title: "تنبيه"; anchors.centerIn: parent; modal: true
        Text { text: "يرجى تعبئة التاريخ والوقت والمبلغ للطلاب الحاضرين قبل إدخال يوم جديد!"; color: "#C0392B" }
    }

    Dialog {
        id: manageAssignmentDialog; title: "متابعة التكليف"; anchors.centerIn: parent; modal: true; width: 350; height: 400
        ColumnLayout {
            anchors.fill: parent
            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true; model: assignmentStudentsModel; clip: true
                delegate: RowLayout {
                    width: parent.width
                    Text { text: model.name; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                    CheckBox { text: "تم الإنجاز"; checked: model.isCompleted; onClicked: assignmentStudentsModel.setProperty(index, "isCompleted", checked) }
                }
            }
            Button {
                text: "حفظ"; Layout.fillWidth: true; highlighted: true
                onClicked: {
                    var data = [];
                    for (var i = 0; i < assignmentStudentsModel.count; i++) {
                        var it = assignmentStudentsModel.get(i);
                        data.push({ "studentId": it.studentId, "isCompleted": it.isCompleted });
                    }
                    dbManager.saveAssignmentStatus(activeAssignmentId, data);
                    manageAssignmentDialog.close();
                }
            }
        }
    }

    // نافذة الغرامات المحدثة التي تحتوي زر "إعفاء"
    Dialog {
        id: studentFinesDialog; title: "تفاصيل غرامات: " + activeStudentName; anchors.centerIn: parent; modal: true; width: 420; height: 400
        ColumnLayout {
            anchors.fill: parent
            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true; model: studentFinesDetailModel; clip: true
                delegate: RowLayout {
                    width: parent.width; spacing: 5
                    Text { text: model.date + " - " + model.amount + " $"; Layout.fillWidth: true }
                    Button {
                        text: model.isPaid ? "تم الدفع" : "تسديد"
                        enabled: !model.isPaid
                        onClicked: {
                            dbManager.markFineAsPaid(model.attendanceId);
                            refreshStudentFinesDetail();
                            refreshFines();
                        }
                    }
                    Button {
                        text: "إعفاء"
                        enabled: !model.isPaid
                        palette.button: "#E74C3C"
                        palette.buttonText: "white"
                        onClicked: {
                            dbManager.waiveFine(model.attendanceId);
                            refreshStudentFinesDetail();
                            refreshFines();
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: studentTaskStatDialog; title: "إحصائية التكاليف"; anchors.centerIn: parent; modal: true
        Text { id: studentTaskStatText; font.pixelSize: 14; horizontalAlignment: Text.AlignRight }
    }

    Dialog {
        id: addStudentDialog; title: "إضافة طالب"; anchors.centerIn: parent; modal: true
        ColumnLayout {
            TextField { id: studentNameInput; placeholderText: "الاسم..." }
            Button { text: "حفظ"; onClicked: { dbManager.addStudent(studentNameInput.text); refreshStudents(); refreshFines(); addStudentDialog.close(); } }
        }
    }

    Dialog {
        id: addAssignmentDialog; title: "إنشاء تكليف عملي"; anchors.centerIn: parent; modal: true
        ColumnLayout {
            TextField { id: assignTitleInput; placeholderText: "عنوان التكليف..." }
            TextField { id: assignTeacherInput; placeholderText: "اسم الاستاذ..." }
            Button { text: "حفظ"; onClicked: { dbManager.addAssignment(assignTitleInput.text, assignTeacherInput.text); refreshAssignments(); addAssignmentDialog.close(); } }
        }
    }
}