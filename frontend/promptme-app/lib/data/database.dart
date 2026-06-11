import 'package:drift/drift.dart';
import '../domain/enums.dart';
import 'connection/connection.dart';
import 'daos/task_dao.dart';
import 'daos/task_event_dao.dart';

part 'database.g.dart';

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().nullable().references(Projects, #id)();
  IntColumn get parentTaskId => integer().nullable()();
  TextColumn get title => text()();
  IntColumn get quadrant => intEnum<Quadrant>()();
  IntColumn get source => intEnum<TaskSource>()();
  DateTimeColumn get scheduledDate => dateTime().nullable()();
  IntColumn get estMinutes => integer().nullable()();
  IntColumn get status => intEnum<TaskStatus>().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get rolloverCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get firstScheduledDate => dateTime().nullable()();
  TextColumn get currentPromptText => text().nullable()();
  IntColumn get downgradeLevel => integer().withDefault(const Constant(0))();
  TextColumn get domain => text().nullable()();
  IntColumn get tomatoEst => integer().nullable()();
  IntColumn get tomatoDone => integer().withDefault(const Constant(0))();
  // ntfy 同步幂等键（桌面捕获带来的客户端 id）；本地新建为 null。
  TextColumn get syncId => text().nullable()();
}

class TaskEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id)();
  IntColumn get type => intEnum<TaskEventType>()();
  IntColumn get reason => intEnum<FailureReason>().nullable()();
  TextColumn get microVersionText => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  // 专注时长（秒）：番茄完成/放弃时记录，用作 MAP「二次喂诊断」信号（短放弃≈动机塌、半途≈能力塌）。
  IntColumn get durationSec => integer().nullable()();
}

class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get url => text()();
  TextColumn get displayName => text()();
  DateTimeColumn get lastFetchedAt => dateTime().nullable()();
}

class CalendarEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subscriptionId => integer().references(Subscriptions, #id)();
  TextColumn get uid => text()();
  TextColumn get title => text()();
  DateTimeColumn get start => dateTime()();
  DateTimeColumn get end => dateTime().nullable()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  TextColumn get calendarName => text().nullable()();
}

@DriftDatabase(
  tables: [Projects, Tasks, TaskEvents, Subscriptions, CalendarEvents],
  daos: [TaskDao, TaskEventDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(tasks, tasks.domain);
          }
          if (from < 3) {
            await m.addColumn(tasks, tasks.tomatoEst);
            await m.addColumn(tasks, tasks.tomatoDone);
          }
          if (from < 4) {
            await m.addColumn(taskEvents, taskEvents.durationSec);
          }
          if (from < 5) {
            await m.addColumn(tasks, tasks.syncId);
          }
        },
      );

}
