import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/Screens/models/add_caliber_model.dart';
import 'package:uuid/uuid.dart';
import '/Screens/models/firearm_model.dart';
import '/Screens/models/main_session_record_model.dart';
import '/Screens/models/user_weapon_model.dart';
import '/core/constant/app_strings.dart';
import '/core/helper/db_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/helper/network_connection_helper.dart';

final _uuid = Uuid();

class FirearmServices {
  Future<Database> get _db async => await DBHelper().database;

  /// Save a list of firearms (replace old data)
  Future<void> saveFirearms(List<FirearmModel> firearms) async {
    final db = await _db;
    await db.delete(AppStrings.firearmTable);

    for (final f in firearms) {
      await db.insert(
        AppStrings.firearmTable,
        f.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Load all firearms
  Future<List<FirearmModel>> loadFirearms() async {
    final db = await _db;
    final result = await db.query(AppStrings.firearmTable);
    return result.map((row) => FirearmModel.fromJson(row)).toList();
  }

//   Future<List<WeaponModel>> getWeaponsByUser(String userId) async {
//   final db = await _db;

//   // 🧩 Query all weapons where userId matches
//   final result = await db.query(
//     AppStrings.weaponTable,
//     where: 'userId = ?',
//     whereArgs: [userId],
//   );

//   // 🗃️ Convert each record into a WeaponModel
//   return result.map((row) {
//     final firearmJson = jsonDecode(row['firearm'] as String);

//     return WeaponModel(
//       weaponId: row['weaponId'] as String?,
//       userId: row['userId'] as String??'',
//       firearm: FirearmModel.fromJson(firearmJson),
//       createdAt: row['createdAt'] != null
//           ? DateTime.tryParse(row['createdAt'] as String)
//           : null,
//     );
//   }).toList();
// }

  Future<void> saveUserWeapons(List<WeaponModel> firearms) async {
   final db = await _db;
  await db.delete(AppStrings.weaponTable);

  for (final weapon in firearms) {
    await db.insert(
      AppStrings.weaponTable,
      {
        'weaponId': weapon.weaponId,
        'userId': weapon.userId,
        'firearm': jsonEncode(weapon.firearm?.toJson()),
        'notes': weapon.notes,
        'createdAt': weapon.createdAt?.toIso8601String(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  }
// Future<List<AddCaliberModel>> loadUserFirearms() async {
//     final db = await _db;
//     final result = await db.query(AppStrings.userFirearmTable);
//     return result.map((row) => AddCaliberModel.fromJson(row)).toList();
//   }
  // /// Insert single firearm
  //  Future<void> saveUserFirearms(List<AddCaliberModel> firearms) async {
  //   final db = await _db;
  //   await db.delete(AppStrings.userFirearmTable);

  //   for (final f in firearms) {
  //     await db.insert(
  //       AppStrings.userFirearmTable,
  //       f.toJson(),
  //       conflictAlgorithm: ConflictAlgorithm.replace,
  //     );
  //   }
  // }
  // Future<void> addUserCustomCaliber(AddCaliberModel addCaliber) async {
  // final db = await _db;

  // final userId = addCaliber.userId ?? '';
  // final caliber = addCaliber.firearm?.caliber ?? '';
  // final type = addCaliber.firearm?.type ?? '';

  // if (userId.isEmpty || caliber.isEmpty || type.isEmpty) {
  //   throw Exception('Missing required data (userId, caliber, or type)');
  // }

  // // 🔍 1️⃣ Check if caliber already exists locally for this user + type
  // final existing = await db.query(
  //   AppStrings.userFirearmTable,
  //   where: 'user_id = ? AND caliber = ? AND type = ?',
  //   whereArgs: [userId, caliber, type],
  // );

  // if (existing.isNotEmpty) {
  //   print('⚠️ Caliber "$caliber" already exists for this user/type');
  //   // Optionally show toast here
  //   // ToastUtils.showError(message: 'This caliber already exists.');
  //   return;
  // }

  // // ✅ 2️⃣ Insert into local SQLite
  // await db.insert(
  //   AppStrings.userFirearmTable,
  //   addCaliber.toJson(),
  //   conflictAlgorithm: ConflictAlgorithm.replace,
  // );

  // print('✅ Added caliber "$caliber" locally for user $userId');

  // // ☁️ 3️⃣ Also add to Firebase (user-specific subcollection)
  // try {
  //   await FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(userId)
  //       .collection('custom_firearms')
  //       .add(addCaliber.toJson());

  //   print('☁️ Synced caliber "$caliber" to Firebase for user $userId');
  // } catch (e) {
  //   print('⚠️ Failed to sync to Firebase: $e');
  // }
  // }

  Future<WeaponModel?> fetchWeaponById(String weaponId) async {
  final db = await _db;

  try {
    final isOnline = await NetworkUtils.hasInternet();

    // 🟢 1️⃣ If online → try to fetch from Firebase
    if (isOnline) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection("weapons")
          .doc(weaponId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final weapon = WeaponModel.fromJson(data);

        // ✅ Save to local DB for offline access
        await db.insert(
          AppStrings.weaponTable,
          {
            'weaponId': weapon.weaponId ?? weaponId,
            'userId': weapon.userId,
            'firearm': jsonEncode(weapon.firearm?.toJson()),
            'createdAt': weapon.createdAt?.toIso8601String(),
            'synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        log("☁️ Loaded weapon from Firebase and saved locally: $weaponId");
        return weapon;
      } else {
        log("⚠️ Weapon not found in Firebase: $weaponId");
      }
    }

    // 🔴 2️⃣ Offline OR not found → use local DB
    final localResult = await db.query(
      AppStrings.weaponTable,
      where: 'weaponId = ?',
      whereArgs: [weaponId],
      limit: 1,
    );

    if (localResult.isNotEmpty) {
      final data = localResult.first;
      final weapon = WeaponModel(
        weaponId: data['weaponId'] as String,
        userId: data['userId'] as String,
        firearm: FirearmModel.fromJson(jsonDecode(data['firearm'] as String)),
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'] as String)
            : null,
      );

      log("📦 Loaded weapon locally (offline mode): $weaponId");
      return weapon;
    }

    log("❌ No weapon found locally or remotely for ID: $weaponId");
    return null;
  } catch (e) {
    log("⚠️ fetchWeaponById error: $e");
    return null;
  }
}
Future<String?> insertWeapon(WeaponModel weapon) async {
  final db = await _db;
  final firearmJson = jsonEncode(weapon.firearm?.toJson());
  String? finalWeaponId;

  // 🔍 Step 1: Prevent duplicate firearm entries for same user
  final existingWeapons = await db.query(
    AppStrings.weaponTable,
    where: 'userId = ? AND firearm = ?',
    whereArgs: [weapon.userId, firearmJson],
    limit: 1,
  );

  if (existingWeapons.isNotEmpty) {
    final existingId = existingWeapons.first['weaponId'] as String;
    print('⚠️ Duplicate firearm found — skipping insert: $existingId');
    return existingId;
  }

  // 🆕 Step 2: Always save locally first
  final localWeaponId = weapon.weaponId?.isNotEmpty == true
      ? weapon.weaponId!
      : _uuid.v4();

  final Map<String, dynamic> localData = {
    'weaponId': localWeaponId,
    'userId': weapon.userId,
    'firearm': firearmJson,
    'createdAt': weapon.createdAt?.toIso8601String(),
    'notes': weapon.notes,
    'synced': 0, // always mark unsynced first
  };

  await db.insert(
    AppStrings.weaponTable,
    localData,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  print('💾 Saved locally: $localWeaponId');

  finalWeaponId = localWeaponId;

  // 🌐 Step 3: If online, sync this weapon immediately
  final isOnline = await NetworkUtils.hasInternet();

  if (isOnline) {
    try {
      final dataWithId = weapon.toJson();
      dataWithId['weaponId'] = localWeaponId;

      await FirebaseFirestore.instance
          .collection("weapons")
          .doc(localWeaponId)
          .set(dataWithId, SetOptions(merge: true));

      // ✅ Update local DB to mark as synced
      await db.update(
        AppStrings.weaponTable,
        {'synced': 1},
        where: 'weaponId = ?',
        whereArgs: [localWeaponId],
      );

      print('☁️ Synced to Firebase: $localWeaponId');
    } catch (e) {
      print('⚠️ Firebase sync failed: $e');
    }
  } else {
    print('📴 Offline — will sync later.');
  }

  return finalWeaponId;
}

  Future<List<WeaponModel>> getWeaponsByUser(String userId) async {
    final db = await _db;
    final res = await db.query(
      AppStrings.weaponTable,
      where: "userId = ?",
      whereArgs: [userId],
    );

    return res.map((e) {
      return WeaponModel(
        weaponId: e['weaponId'] as String,
        userId: e['userId'] as String,
        firearm: FirearmModel.fromJson(jsonDecode(e['firearm'] as String)),
        createdAt:
            e['createdAt'] != null
                ? DateTime.tryParse(e['createdAt'] as String)
                : null,
      );
    }).toList();
  }
Future<void> syncWeaponsFromFirebase(String userId) async {
  final db = await _db;

  final unsyncedWeapons = await db.query(
    AppStrings.weaponTable,
    where: 'synced = ?',
    whereArgs: [0],
  );

  if (unsyncedWeapons.isEmpty) {
    print('✅ No pending weapons to sync.');
    return;
  }

  print('☁️ Syncing ${unsyncedWeapons.length} pending weapons...');

  for (final weapon in unsyncedWeapons) {
    try {
      final weaponId = weapon['weaponId'] as String;
      final firearmJson = weapon['firearm'] as String;
      final firearmMap = jsonDecode(firearmJson);

      final weaponModel = WeaponModel(
        weaponId: weaponId,
        userId: weapon['userId'] as String?,
        firearm: FirearmModel.fromJson(firearmMap),
        notes: weapon['notes'] as String?,
        createdAt: DateTime.tryParse(weapon['createdAt'] as String),
      );

      final data = weaponModel.toJson();
      data['weaponId'] = weaponId;

      await FirebaseFirestore.instance
          .collection('weapons')
          .doc(weaponId)
          .set(data, SetOptions(merge: true));

      await db.update(
        AppStrings.weaponTable,
        {'synced': 1},
        where: 'weaponId = ?',
        whereArgs: [weaponId],
      );

      print('✅ Synced pending weapon: $weaponId');
    } catch (e) {
      print('⚠️ Sync failed for pending weapon: $e');
    }
  }
}

// NOTE: You must ensure 'weaponId' is a primary key or a unique column
// in your 'weaponTable' for 'ConflictAlgorithm.replace' to correctly
// perform the UPSERT (Update or Insert) based on the Firebase ID.
  /// Sync pending weapons with Firebase (direct)
  Future<void> syncPendingWeapons() async {
  final db = await _db;
  final isOnline = await NetworkUtils.hasInternet();

  if (!isOnline) {
    log("Cannot sync: No internet connection.");
    return;
  }

  log("Starting synchronization of unsynced weapons...");

  // 1️⃣ Fetch unsynced records
  final unsyncedRecords = await db.query(
    AppStrings.weaponTable,
    where: 'synced = 0',
  );

  if (unsyncedRecords.isEmpty) {
    log("No unsynced weapons found.");
    return;
  }

  for (var record in unsyncedRecords) {
    final tempWeaponId = (record['weaponId'] ?? '') as String;
    if (tempWeaponId.isEmpty) {
      log("⚠️ Skipping record with missing weaponId");
      continue;
    }

    log("Processing unsynced weapon: $tempWeaponId");

    try {
      // 2️⃣ Decode firearm safely
      final firearmJson = record['firearm'];
      if (firearmJson == null || firearmJson.toString().isEmpty) {
        log("⚠️ Skipping $tempWeaponId — firearm data missing.");
        continue;
      }

      final firearmMap = jsonDecode(firearmJson.toString());

      // 3️⃣ Build WeaponModel safely
      final weaponModel = WeaponModel(
        weaponId: tempWeaponId,
        userId: record['userId']?.toString(),
        firearm: FirearmModel.fromJson(firearmMap),
        createdAt: record['createdAt'] != null
            ? DateTime.tryParse(record['createdAt'].toString())
            : null,
        notes: record['notes']?.toString(),
      );

      final weaponJson = weaponModel.toJson();

      // 4️⃣ Firestore reference
      final weaponsCollection = FirebaseFirestore.instance.collection("weapons");

      // 5️⃣ Check if already exists in Firebase
      final existingDocs = await weaponsCollection
          .where('userId', isEqualTo: weaponModel.userId)
          .where('firearm.model', isEqualTo: weaponModel.firearm?.model)
          .where('firearm.make', isEqualTo: weaponModel.firearm?.make)
          .limit(1)
          .get();

      String firebaseId;

      if (existingDocs.docs.isNotEmpty) {
        // ✅ Update existing document
        final docToUpdate = existingDocs.docs.first;
        firebaseId = docToUpdate.id;
        log("Match found on Firebase → Updating document: $firebaseId");

        await weaponsCollection.doc(firebaseId).set(
              weaponJson,
              SetOptions(merge: true),
            );
      } else {
        // 🆕 Add new document
        log("No match found → Creating new document...");
        final docRef = await weaponsCollection.add(weaponJson);
        firebaseId = docRef.id;
      }

      // 6️⃣ Update local DB with Firebase ID
      final existingLocal = await db.query(
        AppStrings.weaponTable,
        where: 'weaponId = ?',
        whereArgs: [firebaseId],
        limit: 1,
      );

      if (existingLocal.isNotEmpty) {
        // Conflict → delete duplicate
        await db.delete(
          AppStrings.weaponTable,
          where: 'weaponId = ?',
          whereArgs: [tempWeaponId],
        );
        log("⚖️ Conflict resolved: deleted local temp $tempWeaponId");
      } else {
        // Update temp record with final Firebase ID
        await db.update(
          AppStrings.weaponTable,
          {
            'weaponId': firebaseId,
            'synced': 1,
          },
          where: 'weaponId = ?',
          whereArgs: [tempWeaponId],
        );
      }

      log("✅ Synced successfully → Final ID: $firebaseId");
    } catch (e, st) {
      log("❌ Error syncing weapon $tempWeaponId: $e");
      log(st.toString());
    }
  }

  log("✅ Synchronization complete.");
}

  /// Insert Session (offline-first, Firebase auto-ID)
  Future<void> insertSession(MainSessionRecordModel session) async {
    final db = await _db;
    final isOnline = await NetworkUtils.hasInternet();

    if (isOnline) {
      log("Saving synced session record to Firebase (auto-ID)");

      final docRef = await FirebaseFirestore.instance
          .collection("sessions")
          .add(session.toJson());

      final generatedId = docRef.id;

      await db.insert(AppStrings.userSessionTable, {
        'recordId': generatedId,
        'userId': session.userId,
        'weaponId': session.weapon?.weaponId ?? '',
        'targetPaper': session.targetPaper,
        'distance': session.distance,
        'caliber': session.caliber,
        'imagePath': session.imagePath,
        'finalShotResult': jsonEncode(session.finalShotResult),
        'createdAt': session.createdAt?.toIso8601String(),
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      final tempId =
          session.recordId.isNotEmpty ? session.recordId : _uuid.v4();

      log("Saving unsynced session record locally: $tempId");

      await db.insert(AppStrings.userSessionTable, {
        'recordId': tempId,
        'userId': session.userId,
        'weaponId': session.weapon?.weaponId ?? '',
        'targetPaper': session.targetPaper,
        'distance': session.distance,
        'caliber': session.caliber,
        'imagePath': session.imagePath,
        'finalShotResult': jsonEncode(session.finalShotResult),
        'createdAt': session.createdAt?.toIso8601String(),
        'synced': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Sync pending sessions with Firebase (direct)
  Future<void> syncPendingSessions() async {
    final isOnline = await NetworkUtils.hasInternet();
    if (!isOnline) {
      log("Cannot sync sessions: offline.");
      return;
    }

    final db = await _db;
    final unsynced = await db.query(
      AppStrings.userSessionTable,
      where: "synced = ?",
      whereArgs: [0],
    );

    if (unsynced.isEmpty) {
      log("No pending sessions to sync.");
      return;
    }

    // Inlined logic from _syncSessionsTask
    for (final e in unsynced) {
      try {
        final session = MainSessionRecordModel.fromJson({
          ...e,
          "finalShotResult": jsonDecode(e['finalShotResult'] as String),
        });

        // Push to Firebase with auto-ID
        final docRef = await FirebaseFirestore.instance
            .collection("sessions")
            .add(session.toJson());

        final newId = docRef.id;

        // Replace temp ID with Firebase ID and set synced to 1
        await db.update(
          AppStrings.userSessionTable,
          {"recordId": newId, "synced": 1},
          where: "recordId = ?",
          whereArgs: [session.recordId],
        );

        log("✅ Synced session: tempId=${session.recordId} → firebaseId=$newId");
      } catch (err) {
        log("❌ Failed syncing session: $err");
      }
    }
  }

  /// Get Weapons by UserId


  /// Get Sessions by UserId
  Future<List<MainSessionRecordModel>> getSessionsByUser(String userId) async {
    final db = await _db;
    final res = await db.query(
      AppStrings.userSessionTable,
      where: "userId = ?",
      whereArgs: [userId],
    );

    return res.map((e) {
      return MainSessionRecordModel(
        recordId: e['recordId'] as String,
        userId: e['userId'] as String,
        weaponId: e['weaponId'] as String,
        targetPaper: e['targetPaper'] as String,
        distance: e['distance'] as String,
        caliber: e['caliber'] as String,
        imagePath: e['imagePath'] as String,
        finalShotResult: jsonDecode(e['finalShotResult'] as String),
        createdAt:
            e['createdAt'] != null
                ? DateTime.tryParse(e['createdAt'] as String)
                : null,
      );
    }).toList();
  }

  /// Get Weapon by ID
  Future<WeaponModel?> getWeaponById(String weaponId) async {
    final db = await _db;
    final res = await db.query(
      AppStrings.weaponTable,
      where: "weaponId = ?",
      whereArgs: [weaponId],
    );

    if (res.isNotEmpty) {
      final data = res.first;
      return WeaponModel(
        weaponId: data['weaponId'] as String,
        userId: data['userId'] as String,
        firearm: FirearmModel.fromJson(jsonDecode(data['firearm'] as String)),
        createdAt:
            data['createdAt'] != null
                ? DateTime.tryParse(data['createdAt'] as String)
                : null,
      );
    }
    return null;
  }

  /// Get all local data + stats in one method
  Future<Map<String, dynamic>> getAllData() async {
    final db = await DBHelper().database;

    // Weapons
    final weaponRows = await db.query(AppStrings.weaponTable);
    final weapons =
        weaponRows.map((e) {
          return WeaponModel(
            weaponId: e['weaponId'] as String,
            userId: e['userId'] as String,
            firearm: FirearmModel.fromJson(jsonDecode(e['firearm'] as String)),
            createdAt:
                e['createdAt'] != null
                    ? DateTime.tryParse(e['createdAt'] as String)
                    : null,
          );
        }).toList();

    final weaponTotal = weapons.length;
    final weaponPending =
        weaponRows.where((row) => (row['synced'] as int? ?? 0) == 0).length;
    final weaponSynced = weaponTotal - weaponPending;

    // Sessions
    final sessionRows = await db.query(AppStrings.userSessionTable);
    final sessions =
        sessionRows.map((e) {
          return MainSessionRecordModel(
            recordId: e['recordId'] as String,
            userId: e['userId'] as String,
            weaponId: e['weaponId'] as String,
            targetPaper: e['targetPaper'] as String,
            distance: e['distance'] as String,
            caliber: e['caliber'] as String,
            imagePath: e['imagePath'] as String,
            finalShotResult: jsonDecode(e['finalShotResult'] as String),
            createdAt:
                e['createdAt'] != null
                    ? DateTime.tryParse(e['createdAt'] as String)
                    : null,
          );
        }).toList();

    final sessionTotal = sessions.length;
    final sessionPending =
        sessionRows.where((row) => (row['synced'] as int? ?? 0) == 0).length;
    final sessionSynced = sessionTotal - sessionPending;

    // 🎯 Use log() to print the total and pending counts
    log("📊 Data Summary:");
    log(
      "  Weapons Total: $weaponTotal, Pending: $weaponPending, Synced: $weaponSynced",
    );
    log(
      "  Sessions Total: $sessionTotal, Pending: $sessionPending, Synced: $sessionSynced",
    );

    return {
      "weapons": {
        "data": weapons,
        "total": weaponTotal,
        "pending": weaponPending,
        "synced": weaponSynced,
      },
      "sessions": {
        "data": sessions,
        "total": sessionTotal,
        "pending": sessionPending,
        "synced": sessionSynced,
      },
    };
  }
}
// ❌ Removed Background Isolate Tasks functions: _syncWeaponsTask and _syncSessionsTask