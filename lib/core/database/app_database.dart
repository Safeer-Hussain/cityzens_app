import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../utils/exam_cryptography.dart';

class AppDatabase {
  static const String _dbName = 'cityzens_campus.db';
  static const int _dbVersion = 1;

  Database? _db;

  AppDatabase([Database? injectedDb]) : _db = injectedDb;

  Database get db {
    if (_db == null) {
      throw StateError('Database has not been initialized. Call init() first.');
    }
    return _db!;
  }

  bool get isInitialized => _db != null;

  Future<void> init() async {
    if (_db != null) return;
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedInitialData(db);
      },
    );

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS academic_transcripts (
        id TEXT PRIMARY KEY,
        semester_name TEXT NOT NULL,
        credit_hours INTEGER NOT NULL,
        gpa REAL NOT NULL
      )
    ''');

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS exam_hall_passes (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        course_code TEXT NOT NULL,
        course_title TEXT NOT NULL,
        exam_type TEXT NOT NULL,
        exam_date INTEGER NOT NULL,
        duration_minutes INTEGER NOT NULL,
        hall_name TEXT NOT NULL,
        seat_row TEXT NOT NULL,
        seat_number INTEGER NOT NULL,
        desk_number TEXT NOT NULL,
        optical_token TEXT NOT NULL,
        cryptographic_checksum TEXT NOT NULL,
        is_verified INTEGER NOT NULL DEFAULT 0,
        is_reminder_set INTEGER NOT NULL DEFAULT 0,
        reminder_lead_minutes INTEGER NOT NULL DEFAULT 60,
        invigilator_name TEXT NOT NULL,
        instructions TEXT NOT NULL
      )
    ''');

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS study_rooms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        floor INTEGER NOT NULL,
        capacity INTEGER NOT NULL,
        amenities TEXT NOT NULL,
        is_available INTEGER NOT NULL DEFAULT 1,
        photo_asset TEXT NOT NULL
      )
    ''');

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS study_room_bookings (
        id TEXT PRIMARY KEY,
        room_id TEXT NOT NULL,
        room_name TEXT NOT NULL,
        floor INTEGER NOT NULL,
        booked_by_id TEXT NOT NULL,
        booked_by_name TEXT NOT NULL,
        purpose TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        attendees TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS flashcard_decks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        card_count INTEGER NOT NULL DEFAULT 0,
        mastery_percentage REAL NOT NULL DEFAULT 0.0,
        color_hex TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS flashcards (
        id TEXT PRIMARY KEY,
        deck_id TEXT NOT NULL,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        hint TEXT NOT NULL,
        repetitions INTEGER NOT NULL DEFAULT 0,
        interval_days INTEGER NOT NULL DEFAULT 1,
        ease_factor REAL NOT NULL DEFAULT 2.5,
        next_review_date INTEGER NOT NULL,
        last_reviewed_date INTEGER,
        mastery_level TEXT NOT NULL DEFAULT 'learning',
        created_at INTEGER NOT NULL
      )
    ''');

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS flashcard_reviews (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        deck_id TEXT NOT NULL,
        quality INTEGER NOT NULL,
        interval_days INTEGER NOT NULL,
        ease_factor REAL NOT NULL,
        reviewed_at INTEGER NOT NULL
      )
    ''');

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS cafeteria_menu_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        calories INTEGER NOT NULL,
        protein_g REAL NOT NULL,
        carbs_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        dietary_tags TEXT NOT NULL,
        dining_hall TEXT NOT NULL,
        operational_hours TEXT NOT NULL,
        is_available INTEGER NOT NULL DEFAULT 1,
        image_asset TEXT NOT NULL
      )
    ''');

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS student_wallets (
        student_id TEXT PRIMARY KEY,
        balance REAL NOT NULL DEFAULT 150.0,
        reward_points INTEGER NOT NULL DEFAULT 320,
        last_reloaded_at INTEGER NOT NULL
      )
    ''');

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS cafeteria_orders (
        id TEXT PRIMARY KEY,
        order_number TEXT NOT NULL,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        dining_hall TEXT NOT NULL,
        items_json TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0.0,
        final_amount REAL NOT NULL,
        total_calories INTEGER NOT NULL,
        total_protein_g REAL NOT NULL,
        total_carbs_g REAL NOT NULL,
        total_fat_g REAL NOT NULL,
        allergy_flags TEXT NOT NULL,
        special_instructions TEXT NOT NULL,
        status TEXT NOT NULL,
        pickup_time TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        nfc_token TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS parking_zones (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        campus_area TEXT NOT NULL,
        total_spots INTEGER NOT NULL,
        occupied_spots INTEGER NOT NULL,
        total_ev_spots INTEGER NOT NULL,
        occupied_ev_spots INTEGER NOT NULL,
        hourly_rate REAL NOT NULL,
        operational_hours TEXT NOT NULL,
        is_covered INTEGER NOT NULL,
        charger_types TEXT NOT NULL
      )
    ''');

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS parking_permits (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        vehicle_plate TEXT NOT NULL,
        vehicle_model TEXT NOT NULL,
        permit_tier TEXT NOT NULL,
        valid_from INTEGER NOT NULL,
        valid_until INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        assigned_zone TEXT NOT NULL,
        rfid_token TEXT NOT NULL,
        barcode_payload TEXT NOT NULL
      )
    ''');

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS ev_charging_reservations (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        zone_id TEXT NOT NULL,
        zone_name TEXT NOT NULL,
        station_id TEXT NOT NULL,
        charger_type TEXT NOT NULL,
        slot_time TEXT NOT NULL,
        target_battery_percent INTEGER NOT NULL,
        estimated_energy_kwh REAL NOT NULL,
        cost_credits REAL NOT NULL,
        queue_token TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS timetable_slots (
        id TEXT PRIMARY KEY,
        course_id TEXT NOT NULL,
        course_code TEXT NOT NULL,
        course_title TEXT NOT NULL,
        section_name TEXT NOT NULL,
        instructor TEXT NOT NULL,
        room TEXT NOT NULL,
        day_of_week INTEGER NOT NULL,
        start_time_minutes INTEGER NOT NULL,
        end_time_minutes INTEGER NOT NULL,
        is_lab INTEGER NOT NULL DEFAULT 0,
        is_enrolled INTEGER NOT NULL DEFAULT 0
      )
    ''');

    final transcriptCount =
        Sqflite.firstIntValue(
          await _db!.rawQuery('SELECT COUNT(*) FROM academic_transcripts'),
        ) ??
        0;
    if (transcriptCount == 0) {
      await _seedTranscripts(_db!);
    }

    final passCount =
        Sqflite.firstIntValue(
          await _db!.rawQuery('SELECT COUNT(*) FROM exam_hall_passes'),
        ) ??
        0;
    if (passCount == 0) {
      await _seedExamPasses(_db!);
    }

    final studyRoomCount =
        Sqflite.firstIntValue(
          await _db!.rawQuery('SELECT COUNT(*) FROM study_rooms'),
        ) ??
        0;
    if (studyRoomCount == 0) {
      await _seedStudyRooms(_db!);
      await _seedStudyRoomBookings(_db!);
    }

    final flashcardDeckCount =
        Sqflite.firstIntValue(
          await _db!.rawQuery('SELECT COUNT(*) FROM flashcard_decks'),
        ) ??
        0;
    if (flashcardDeckCount == 0) {
      await _seedFlashcards(_db!);
    }

    final cafeteriaItemCount =
        Sqflite.firstIntValue(
          await _db!.rawQuery('SELECT COUNT(*) FROM cafeteria_menu_items'),
        ) ??
        0;
    if (cafeteriaItemCount == 0) {
      await _seedCafeteriaData(_db!);
    }

    final parkingZoneCount =
        Sqflite.firstIntValue(
          await _db!.rawQuery('SELECT COUNT(*) FROM parking_zones'),
        ) ??
        0;
    if (parkingZoneCount == 0) {
      await _seedParkingData(_db!);
    }

    final timetableSlotCount =
        Sqflite.firstIntValue(
          await _db!.rawQuery('SELECT COUNT(*) FROM timetable_slots'),
        ) ??
        0;
    if (timetableSlotCount == 0) {
      await _seedTimetableSlots(_db!);
    }
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        title TEXT NOT NULL,
        instructor TEXT NOT NULL,
        room TEXT NOT NULL,
        schedule TEXT NOT NULL,
        present_count INTEGER NOT NULL DEFAULT 0,
        absent_count INTEGER NOT NULL DEFAULT 0,
        excused_count INTEGER NOT NULL DEFAULT 0,
        total_classes INTEGER NOT NULL DEFAULT 0,
        min_required_percentage REAL NOT NULL DEFAULT 75.0
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_ledger (
        id TEXT PRIMARY KEY,
        course_id TEXT NOT NULL,
        course_code TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        status TEXT NOT NULL,
        verification_method TEXT NOT NULL,
        notes TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE library_books (
        id TEXT PRIMARY KEY,
        isbn TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        category TEXT NOT NULL,
        shelf_location TEXT NOT NULL,
        total_copies INTEGER NOT NULL,
        available_copies INTEGER NOT NULL,
        is_reserved INTEGER NOT NULL DEFAULT 0,
        abstract TEXT NOT NULL,
        table_of_contents TEXT NOT NULL,
        cover_asset TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE library_loans (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        borrower_id TEXT NOT NULL,
        borrow_date INTEGER NOT NULL,
        due_date INTEGER NOT NULL,
        is_returned INTEGER NOT NULL DEFAULT 0,
        renewal_count INTEGER NOT NULL DEFAULT 0,
        overdue_fine REAL NOT NULL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE campus_posts (
        id TEXT PRIMARY KEY,
        author_name TEXT NOT NULL,
        author_role TEXT NOT NULL,
        author_avatar TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        likes_count INTEGER NOT NULL DEFAULT 0,
        is_liked INTEGER NOT NULL DEFAULT 0,
        comments_count INTEGER NOT NULL DEFAULT 0,
        is_bookmarked INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE campus_comments (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL,
        author_name TEXT NOT NULL,
        author_role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE leave_requests (
        id TEXT PRIMARY KEY,
        course_code TEXT NOT NULL,
        reason TEXT NOT NULL,
        date INTEGER NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE academic_transcripts (
        id TEXT PRIMARY KEY,
        semester_name TEXT NOT NULL,
        credit_hours INTEGER NOT NULL,
        gpa REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE exam_hall_passes (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        course_code TEXT NOT NULL,
        course_title TEXT NOT NULL,
        exam_type TEXT NOT NULL,
        exam_date INTEGER NOT NULL,
        duration_minutes INTEGER NOT NULL,
        hall_name TEXT NOT NULL,
        seat_row TEXT NOT NULL,
        seat_number INTEGER NOT NULL,
        desk_number TEXT NOT NULL,
        optical_token TEXT NOT NULL,
        cryptographic_checksum TEXT NOT NULL,
        is_verified INTEGER NOT NULL DEFAULT 0,
        is_reminder_set INTEGER NOT NULL DEFAULT 0,
        reminder_lead_minutes INTEGER NOT NULL DEFAULT 60,
        invigilator_name TEXT NOT NULL,
        instructions TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE study_rooms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        floor INTEGER NOT NULL,
        capacity INTEGER NOT NULL,
        amenities TEXT NOT NULL,
        is_available INTEGER NOT NULL DEFAULT 1,
        photo_asset TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE study_room_bookings (
        id TEXT PRIMARY KEY,
        room_id TEXT NOT NULL,
        room_name TEXT NOT NULL,
        floor INTEGER NOT NULL,
        booked_by_id TEXT NOT NULL,
        booked_by_name TEXT NOT NULL,
        purpose TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        attendees TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE flashcard_decks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        card_count INTEGER NOT NULL DEFAULT 0,
        mastery_percentage REAL NOT NULL DEFAULT 0.0,
        color_hex TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE flashcards (
        id TEXT PRIMARY KEY,
        deck_id TEXT NOT NULL,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        hint TEXT NOT NULL,
        repetitions INTEGER NOT NULL DEFAULT 0,
        interval_days INTEGER NOT NULL DEFAULT 1,
        ease_factor REAL NOT NULL DEFAULT 2.5,
        next_review_date INTEGER NOT NULL,
        last_reviewed_date INTEGER,
        mastery_level TEXT NOT NULL DEFAULT 'learning',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE flashcard_reviews (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        deck_id TEXT NOT NULL,
        quality INTEGER NOT NULL,
        interval_days INTEGER NOT NULL,
        ease_factor REAL NOT NULL,
        reviewed_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cafeteria_menu_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        calories INTEGER NOT NULL,
        protein_g REAL NOT NULL,
        carbs_g REAL NOT NULL,
        fat_g REAL NOT NULL,
        dietary_tags TEXT NOT NULL,
        dining_hall TEXT NOT NULL,
        operational_hours TEXT NOT NULL,
        is_available INTEGER NOT NULL DEFAULT 1,
        image_asset TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE student_wallets (
        student_id TEXT PRIMARY KEY,
        balance REAL NOT NULL DEFAULT 150.0,
        reward_points INTEGER NOT NULL DEFAULT 320,
        last_reloaded_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cafeteria_orders (
        id TEXT PRIMARY KEY,
        order_number TEXT NOT NULL,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        dining_hall TEXT NOT NULL,
        items_json TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0.0,
        final_amount REAL NOT NULL,
        total_calories INTEGER NOT NULL,
        total_protein_g REAL NOT NULL,
        total_carbs_g REAL NOT NULL,
        total_fat_g REAL NOT NULL,
        allergy_flags TEXT NOT NULL,
        special_instructions TEXT NOT NULL,
        status TEXT NOT NULL,
        pickup_time TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        nfc_token TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE parking_zones (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        campus_area TEXT NOT NULL,
        total_spots INTEGER NOT NULL,
        occupied_spots INTEGER NOT NULL,
        total_ev_spots INTEGER NOT NULL,
        occupied_ev_spots INTEGER NOT NULL,
        hourly_rate REAL NOT NULL,
        operational_hours TEXT NOT NULL,
        is_covered INTEGER NOT NULL,
        charger_types TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE parking_permits (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        vehicle_plate TEXT NOT NULL,
        vehicle_model TEXT NOT NULL,
        permit_tier TEXT NOT NULL,
        valid_from INTEGER NOT NULL,
        valid_until INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        assigned_zone TEXT NOT NULL,
        rfid_token TEXT NOT NULL,
        barcode_payload TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ev_charging_reservations (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        zone_id TEXT NOT NULL,
        zone_name TEXT NOT NULL,
        station_id TEXT NOT NULL,
        charger_type TEXT NOT NULL,
        slot_time TEXT NOT NULL,
        target_battery_percent INTEGER NOT NULL,
        estimated_energy_kwh REAL NOT NULL,
        cost_credits REAL NOT NULL,
        queue_token TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE timetable_slots (
        id TEXT PRIMARY KEY,
        course_id TEXT NOT NULL,
        course_code TEXT NOT NULL,
        course_title TEXT NOT NULL,
        section_name TEXT NOT NULL,
        instructor TEXT NOT NULL,
        room TEXT NOT NULL,
        day_of_week INTEGER NOT NULL,
        start_time_minutes INTEGER NOT NULL,
        end_time_minutes INTEGER NOT NULL,
        is_lab INTEGER NOT NULL DEFAULT 0,
        is_enrolled INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> _seedInitialData(Database db) async {
    // 1. Seed Courses
    final courses = [
      {
        'id': 'crs_01',
        'code': 'CS-401',
        'title': 'Distributed Systems & Cloud Computing',
        'instructor': 'Dr. Aris Thorne',
        'room': 'Alan Turing Hall 302',
        'schedule': 'Mon & Wed 09:00 - 10:30',
        'present_count': 22,
        'absent_count': 2,
        'excused_count': 1,
        'total_classes': 25,
        'min_required_percentage': 75.0,
      },
      {
        'id': 'crs_02',
        'code': 'CS-405',
        'title': 'Advanced Mobile Architecture & Low-Level Kernels',
        'instructor': 'Prof. Evelyn Vance',
        'room': 'Grace Hopper Hall 101',
        'schedule': 'Tue & Thu 11:00 - 12:30',
        'present_count': 24,
        'absent_count': 0,
        'excused_count': 1,
        'total_classes': 25,
        'min_required_percentage': 75.0,
      },
      {
        'id': 'crs_03',
        'code': 'AI-410',
        'title': 'Applied Artificial Intelligence & Neural Heuristics',
        'instructor': 'Dr. Marcus Holloway',
        'room': 'Shannon Computing Lab 204',
        'schedule': 'Mon & Fri 14:00 - 15:30',
        'present_count': 19,
        'absent_count': 4,
        'excused_count': 1,
        'total_classes': 24,
        'min_required_percentage': 75.0,
      },
      {
        'id': 'crs_04',
        'code': 'SE-420',
        'title': 'Domain-Driven Enterprise Software Engineering',
        'instructor': 'Prof. Claire Sterling',
        'room': 'Lovelace Lecture Theater 401',
        'schedule': 'Wed & Fri 16:00 - 17:30',
        'present_count': 21,
        'absent_count': 1,
        'excused_count': 0,
        'total_classes': 22,
        'min_required_percentage': 75.0,
      },
      {
        'id': 'crs_05',
        'code': 'SEC-430',
        'title': 'Zero-Trust Cryptographic Infrastructure',
        'instructor': 'Dr. Nathan Drake',
        'room': 'Knuth Security Center B12',
        'schedule': 'Thu 14:00 - 17:00',
        'present_count': 18,
        'absent_count': 3,
        'excused_count': 1,
        'total_classes': 22,
        'min_required_percentage': 75.0,
      },
    ];

    for (final c in courses) {
      await db.insert('courses', c);
    }

    // 2. Seed Attendance Records
    final now = DateTime.now();
    final ledgerItems = [
      {
        'id': 'att_01',
        'course_id': 'crs_01',
        'course_code': 'CS-401',
        'timestamp': now
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch,
        'status': 'present',
        'verification_method': 'native_qr',
        'notes': 'Verified optical QR token scan at Turing Hall entrance.',
      },
      {
        'id': 'att_02',
        'course_id': 'crs_02',
        'course_code': 'CS-405',
        'timestamp': now
            .subtract(const Duration(days: 2))
            .millisecondsSinceEpoch,
        'status': 'present',
        'verification_method': 'native_qr',
        'notes': 'Verified optical QR token scan at Hopper Auditorium.',
      },
      {
        'id': 'att_03',
        'course_id': 'crs_03',
        'course_code': 'AI-410',
        'timestamp': now
            .subtract(const Duration(days: 3))
            .millisecondsSinceEpoch,
        'status': 'absent',
        'verification_method': 'unverified',
        'notes': 'Missed lecture - AI laboratory session.',
      },
      {
        'id': 'att_04',
        'course_id': 'crs_04',
        'course_code': 'SE-420',
        'timestamp': now
            .subtract(const Duration(days: 5))
            .millisecondsSinceEpoch,
        'status': 'present',
        'verification_method': 'manual_pin',
        'notes': 'Faculty override PIN validation (Pin: 892014).',
      },
      {
        'id': 'att_05',
        'course_id': 'crs_05',
        'course_code': 'SEC-430',
        'timestamp': now
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch,
        'status': 'excused',
        'verification_method': 'leave_request',
        'notes': 'Dean sanctioned medical leave request #LR-9921.',
      },
    ];

    for (final item in ledgerItems) {
      await db.insert('attendance_ledger', item);
    }

    // 3. Seed 42 Comprehensive Books
    final books = _generate42Books();
    for (final b in books) {
      await db.insert('library_books', b);
    }

    // 4. Seed Initial Active Loans (3 loans: 2 healthy, 1 due soon/overdue)
    final loans = [
      {
        'id': 'loan_01',
        'book_id': 'book_01',
        'borrower_id': 'CTZ-2026-8842',
        'borrow_date': now
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
        'due_date': now.add(const Duration(days: 4)).millisecondsSinceEpoch,
        'is_returned': 0,
        'renewal_count': 0,
        'overdue_fine': 0.0,
      },
      {
        'id': 'loan_02',
        'book_id': 'book_02',
        'borrower_id': 'CTZ-2026-8842',
        'borrow_date': now
            .subtract(const Duration(days: 18))
            .millisecondsSinceEpoch,
        'due_date': now
            .subtract(const Duration(days: 2))
            .millisecondsSinceEpoch,
        'is_returned': 0,
        'renewal_count': 1,
        'overdue_fine': 1.0, // 2 days * $0.50
      },
      {
        'id': 'loan_03',
        'book_id': 'book_03',
        'borrower_id': 'CTZ-2026-8842',
        'borrow_date': now
            .subtract(const Duration(days: 6))
            .millisecondsSinceEpoch,
        'due_date': now.add(const Duration(days: 8)).millisecondsSinceEpoch,
        'is_returned': 0,
        'renewal_count': 0,
        'overdue_fine': 0.0,
      },
    ];

    for (final l in loans) {
      await db.insert('library_loans', l);
    }

    // 5. Seed Campus Community Posts & Comments
    final posts = [
      {
        'id': 'post_01',
        'author_name': 'Dr. Aris Thorne',
        'author_role': 'Dean of Distributed Systems Research',
        'author_avatar': 'AT',
        'title': 'Distributed Consensus Workshop: Raft vs Paxos in Production',
        'content': 'We are hosting a high-throughput systems workshop this Thursday at 14:00 in Alan Turing Hall 302. Bring your laptops configured with Go and Docker. All registered seniors are welcome.',
        'category': 'Faculty Announcement',
        'timestamp': now
            .subtract(const Duration(hours: 3))
            .millisecondsSinceEpoch,
        'likes_count': 42,
        'is_liked': 1,
        'comments_count': 3,
        'is_bookmarked': 1,
      },
      {
        'id': 'post_02',
        'author_name': 'Prof. Evelyn Vance',
        'author_role': 'Head of Mobile Architectures Lab',
        'author_avatar': 'EV',
        'title':
            'Undergraduate Research Assistantship: Next-Gen Native Runtimes',
        'content': 'Our lab has two funded openings for research assistants specializing in Dart compiler internals, Skia/Impeller rendering pipeline optimizations, and zero-cost native bridges. Submit portfolios via the departmental portal.',
        'category': 'Research Group',
        'timestamp': now
            .subtract(const Duration(hours: 9))
            .millisecondsSinceEpoch,
        'likes_count': 67,
        'is_liked': 0,
        'comments_count': 2,
        'is_bookmarked': 0,
      },
      {
        'id': 'post_03',
        'author_name': 'Safeer Hussain',
        'author_role': 'Senior Mobile Architect / CS Honours',
        'author_avatar': 'SH',
        'title': 'Offline-First Smart Campus Architecture Whitepaper Released',
        'content': 'Published comprehensive architecture blueprints demonstrating a 15.4% boost in screen load times and 25.1% UI frame render boost using local SQLite caching, MethodChannel optical sensors, and reactive MVVM providers. Benchmarks verified on Android SDK 36.',
        'category': 'Campus Event',
        'timestamp': now
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch,
        'likes_count': 114,
        'is_liked': 1,
        'comments_count': 4,
        'is_bookmarked': 1,
      },
      {
        'id': 'post_04',
        'author_name': 'Library Services Directorate',
        'author_role': 'University Library Administration',
        'author_avatar': 'LB',
        'title':
            '24/7 Silent Study Wing & Digital Repository Upgrade Completed',
        'content': 'Floor 3 and the Turing Reference Hall are now open 24/7 with RFID optical self-checkout kiosks. Over 40 new reference volumes on AI Agents and Cloud Native Security have been cataloged.',
        'category': 'Lab Access',
        'timestamp': now
            .subtract(const Duration(days: 2))
            .millisecondsSinceEpoch,
        'likes_count': 58,
        'is_liked': 0,
        'comments_count': 1,
        'is_bookmarked': 0,
      },
    ];

    for (final p in posts) {
      await db.insert('campus_posts', p);
    }

    final comments = [
      {
        'id': 'comm_01',
        'post_id': 'post_01',
        'author_name': 'Safeer Hussain',
        'author_role': 'Senior Student / Architect',
        'content':
            'Looking forward to the Raft state machine partition benchmarks.',
        'timestamp': now
            .subtract(const Duration(hours: 2))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'comm_02',
        'post_id': 'post_01',
        'author_name': 'Maya Lin',
        'author_role': 'Graduate Researcher',
        'content': 'Will the cluster nodes be deployed across local Raspberry Pi clusters or AWS nodes?',
        'timestamp': now
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'comm_03',
        'post_id': 'post_03',
        'author_name': 'Dr. Aris Thorne',
        'author_role': 'Faculty',
        'content': 'Exceptional benchmarking methodology, Safeer. The memory footprint stays under 60MB.',
        'timestamp': now
            .subtract(const Duration(hours: 18))
            .millisecondsSinceEpoch,
      },
    ];

    for (final c in comments) {
      await db.insert('campus_comments', c);
    }

    // 6. Seed Academic Transcripts for Safeer Hussain (CGPA: 3.94)
    await _seedTranscripts(db);

    // 7. Seed Exam Hall Passes
    await _seedExamPasses(db);

    // 8. Seed Study Rooms & Initial Bookings
    await _seedStudyRooms(db);
    await _seedStudyRoomBookings(db);

    // 9. Seed Flashcard Decks & Spaced Repetition Cards
    await _seedFlashcards(db);

    // 10. Seed Cafeteria Menu Items, Student Wallet & Orders
    await _seedCafeteriaData(db);

    // 11. Seed Parking Zones, Permits & EV Reservations
    await _seedParkingData(db);

    // 12. Seed Academic Timetable Slots & Conflict Scenarios
    await _seedTimetableSlots(db);
  }

  static Future<void> _seedTranscripts(Database db) async {
    final transcripts = [
      {
        'id': 'sem_01',
        'semester_name': 'Semester 1 (Fall 2023)',
        'credit_hours': 17,
        'gpa': 3.92,
      },
      {
        'id': 'sem_02',
        'semester_name': 'Semester 2 (Spring 2024)',
        'credit_hours': 18,
        'gpa': 3.95,
      },
      {
        'id': 'sem_03',
        'semester_name': 'Semester 3 (Fall 2024)',
        'credit_hours': 17,
        'gpa': 3.90,
      },
      {
        'id': 'sem_04',
        'semester_name': 'Semester 4 (Spring 2025)',
        'credit_hours': 18,
        'gpa': 3.96,
      },
      {
        'id': 'sem_05',
        'semester_name': 'Semester 5 (Fall 2025)',
        'credit_hours': 16,
        'gpa': 3.94,
      },
      {
        'id': 'sem_06',
        'semester_name': 'Semester 6 (Spring 2026)',
        'credit_hours': 16,
        'gpa': 3.98,
      },
      {
        'id': 'sem_07',
        'semester_name': 'Semester 7 (Fall 2026)',
        'credit_hours': 16,
        'gpa': 3.92,
      },
    ];

    for (final t in transcripts) {
      await db.insert(
        'academic_transcripts',
        t,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static List<Map<String, dynamic>> _generate42Books() {
    final List<Map<String, dynamic>> books = [
      {
        'id': 'book_01',
        'isbn': '978-0134494166',
        'title':
            "Clean Architecture: A Craftsman's Guide to Software Structure",
        'author': 'Robert C. Martin',
        'category': 'Software Engineering',
        'shelf_location': 'FLOOR-2 / AISLE-A / BAY-01',
        'total_copies': 6,
        'available_copies': 4,
        'is_reserved': 0,
        'abstract': 'Building upon the universal rules of software architecture, Uncle Bob explains how to develop architectures that keep software resilient to technological churn and easy to maintain.',
        'table_of_contents': jsonEncode([
          'Chapter 1: What is Design and Architecture?',
          'Chapter 2: A Tale of Two Values',
          'Chapter 3: Paradigm Overview',
          'Chapter 4: Structured Programming',
          'Chapter 5: Object-Oriented Programming',
          'Chapter 6: Functional Programming',
          'Chapter 7: Single Responsibility Principle',
          'Chapter 8: Open-Closed Principle',
          'Chapter 9: Liskov Substitution Principle',
          'Chapter 10: Interface Segregation Principle',
        ]),
        'cover_asset': 'assets/images/book_clean_architecture.png',
      },
      {
        'id': 'book_02',
        'isbn': '978-0132350884',
        'title': 'Clean Code: A Handbook of Agile Software Craftsmanship',
        'author': 'Robert C. Martin',
        'category': 'Software Engineering',
        'shelf_location': 'FLOOR-2 / AISLE-A / BAY-02',
        'total_copies': 5,
        'available_copies': 2,
        'is_reserved': 1,
        'abstract': 'Even bad code can function. But if code isn’t clean, it can bring a development organization to its knees. Every year, countless hours and significant resources are lost because of poorly written code.',
        'table_of_contents': jsonEncode([
          'Chapter 1: Clean Code',
          'Chapter 2: Meaningful Names',
          'Chapter 3: Functions',
          'Chapter 4: Comments',
          'Chapter 5: Formatting',
          'Chapter 6: Objects and Data Structures',
          'Chapter 7: Error Handling',
          'Chapter 8: Boundaries',
        ]),
        'cover_asset': 'assets/images/book_clean_architecture.png',
      },
      {
        'id': 'book_03',
        'isbn': '978-1491950357',
        'title': 'Designing Data-Intensive Applications',
        'author': 'Martin Kleppmann',
        'category': 'Cloud & Security',
        'shelf_location': 'FLOOR-3 / AISLE-B / BAY-04',
        'total_copies': 8,
        'available_copies': 3,
        'is_reserved': 0,
        'abstract': 'Data is at the center of many challenges in system design today. Difficult issues need to be figured out, such as scalability, consistency, reliability, efficiency, and maintainability.',
        'table_of_contents': jsonEncode([
          'Part I: Foundations of Data Systems',
          'Part II: Distributed Data',
          'Part III: Derived Data',
          'Chapter 5: Replication',
          'Chapter 6: Partitioning',
          'Chapter 7: Transactions',
          'Chapter 8: The Trouble with Distributed Systems',
          'Chapter 9: Consistency and Consensus',
        ]),
        'cover_asset': 'assets/images/book_distributed_databases.png',
      },
      {
        'id': 'book_04',
        'isbn': '978-0262033848',
        'title': 'Introduction to Algorithms (CLRS 4th Edition)',
        'author': 'Thomas H. Cormen, Charles E. Leiserson',
        'category': 'Software Engineering',
        'shelf_location': 'FLOOR-1 / AISLE-C / BAY-08',
        'total_copies': 12,
        'available_copies': 7,
        'is_reserved': 0,
        'abstract': 'A comprehensive textbook covering the complete spectrum of modern algorithms, from sorting and data structures to dynamic programming, graph algorithms, and NP-completeness.',
        'table_of_contents': jsonEncode([
          'Section I: Foundations',
          'Section II: Sorting and Order Statistics',
          'Section III: Data Structures',
          'Section IV: Advanced Design and Analysis Techniques',
          'Section V: Advanced Data Structures',
          'Section VI: Graph Algorithms',
          'Section VII: Selected Topics',
        ]),
        'cover_asset': 'assets/images/book_clean_architecture.png',
      },
      {
        'id': 'book_05',
        'isbn': '978-0262035613',
        'title': 'Deep Learning: Adaptive Computation and Machine Learning',
        'author': 'Ian Goodfellow, Yoshua Bengio, Aaron Courville',
        'category': 'AI & ML',
        'shelf_location': 'FLOOR-3 / AISLE-D / BAY-12',
        'total_copies': 7,
        'available_copies': 5,
        'is_reserved': 0,
        'abstract': 'The deep learning textbook written by pioneering researchers, covering linear algebra, probability, numerical computation, deep feedforward networks, regularization, and generative models.',
        'table_of_contents': jsonEncode([
          'Part I: Applied Math and Machine Learning Basics',
          'Part II: Deep Networks: Modern Practices',
          'Part III: Deep Learning Research',
          'Chapter 6: Deep Feedforward Networks',
          'Chapter 7: Regularization for Deep Learning',
          'Chapter 8: Optimization for Training Deep Models',
        ]),
        'cover_asset': 'assets/images/book_applied_ai.png',
      },
      {
        'id': 'book_06',
        'isbn': '978-0131103627',
        'title': 'The C Programming Language (2nd Edition)',
        'author': 'Brian W. Kernighan, Dennis M. Ritchie',
        'category': 'Systems & Architecture',
        'shelf_location': 'FLOOR-1 / AISLE-A / BAY-03',
        'total_copies': 10,
        'available_copies': 6,
        'is_reserved': 0,
        'abstract': 'The definitive reference guide to C programming authored by the creators of C and Unix. Essential reading for low-level systems engineers.',
        'table_of_contents': jsonEncode([
          'Chapter 1: A Tutorial Introduction',
          'Chapter 2: Types, Operators, and Expressions',
          'Chapter 3: Control Flow',
          'Chapter 4: Functions and Program Structure',
          'Chapter 5: Pointers and Arrays',
          'Chapter 6: Structures',
          'Chapter 7: Input and Output',
        ]),
        'cover_asset': 'assets/images/book_mobile_systems.png',
      },
      {
        'id': 'book_07',
        'isbn': '978-1449373320',
        'title': 'Designing Distributed Systems: Patterns and Paradigms',
        'author': 'Brendan Burns',
        'category': 'Cloud & Security',
        'shelf_location': 'FLOOR-3 / AISLE-C / BAY-09',
        'total_copies': 6,
        'available_copies': 4,
        'is_reserved': 0,
        'abstract': 'Brendan Burns, co-founder of Kubernetes, explains how you can adapt and apply repeatable, generic design patterns for building scalable and reliable distributed applications.',
        'table_of_contents': jsonEncode([
          'Chapter 1: Introduction to Distributed Systems',
          'Chapter 2: Sidecar Pattern',
          'Chapter 3: Ambassador Pattern',
          'Chapter 4: Adapter Pattern',
          'Chapter 5: Replicated Load-Balanced Services',
        ]),
        'cover_asset': 'assets/images/book_distributed_databases.png',
      },
      {
        'id': 'book_08',
        'isbn': '978-0134685991',
        'title': 'Effective Java (3rd Edition)',
        'author': 'Joshua Bloch',
        'category': 'Software Engineering',
        'shelf_location': 'FLOOR-2 / AISLE-A / BAY-05',
        'total_copies': 8,
        'available_copies': 5,
        'is_reserved': 0,
        'abstract': 'The definitive best-practices guide covering 90 concise rules for writing robust, readable, and maintainable object-oriented software.',
        'table_of_contents': jsonEncode([
          'Chapter 2: Creating and Destroying Objects',
          'Chapter 3: Methods Common to All Objects',
          'Chapter 4: Classes and Interfaces',
          'Chapter 5: Generics',
          'Chapter 6: Enums and Annotations',
          'Chapter 7: Lambdas and Streams',
        ]),
        'cover_asset': 'assets/images/book_clean_architecture.png',
      },
      {
        'id': 'book_09',
        'isbn': '978-0132354790',
        'title': 'Database Internals: A Deep Dive into Distributed Engines',
        'author': 'Alex Petrov',
        'category': 'Systems & Architecture',
        'shelf_location': 'FLOOR-3 / AISLE-B / BAY-11',
        'total_copies': 5,
        'available_copies': 2,
        'is_reserved': 0,
        'abstract': 'When it comes to choosing, using, and maintaining a database, understanding its internal machinery is paramount. Explores B-Trees, LSM-Trees, and Distributed Consensus.',
        'table_of_contents': jsonEncode([
          'Part I: Storage Engines',
          'Chapter 1: Storage Engine Overview',
          'Chapter 2: B-Tree Basics',
          'Chapter 3: File Formats and Compaction',
          'Part II: Distributed Systems and Consensus',
        ]),
        'cover_asset': 'assets/images/book_distributed_databases.png',
      },
      {
        'id': 'book_10',
        'isbn': '978-1492040767',
        'title': 'Flutter in Action: Native Cross-Platform Engineering',
        'author': 'Eric Windmill',
        'category': 'Systems & Architecture',
        'shelf_location': 'FLOOR-2 / AISLE-C / BAY-15',
        'total_copies': 9,
        'available_copies': 4,
        'is_reserved': 0,
        'abstract': 'Teaches you to build beautiful, responsive native mobile applications using Flutter and Dart. Covers the widget tree, state management, render objects, and native platform channels.',
        'table_of_contents': jsonEncode([
          'Chapter 1: Meet Flutter',
          'Chapter 2: Dart Foundations',
          'Chapter 3: The Widget Tree Architecture',
          'Chapter 4: State Management Patterns',
          'Chapter 5: Platform Channels and Native Bridging',
        ]),
        'cover_asset': 'assets/images/book_mobile_systems.png',
      },
    ];

    // Seed remaining 32 books programmatically to ensure 42 total books
    final categories = [
      'Software Engineering',
      'AI & ML',
      'Cloud & Security',
      'Systems & Architecture',
    ];

    final sampleTitles = [
      'Site Reliability Engineering: How Google Runs Production Systems',
      'Reinforcement Learning: An Introduction (2nd Edition)',
      'Artificial Intelligence: A Modern Approach (4th Edition)',
      'Computer Networking: A Top-Down Approach',
      'Operating Systems: Three Easy Pieces',
      'Computer Architecture: A Quantitative Approach',
      'Structure and Interpretation of Computer Programs',
      'Programming Rust: Fast, Safe Systems Development',
      'Refactoring: Improving the Design of Existing Code',
      'Domain-Driven Design: Tackling Complexity in Software',
      'Microservices Patterns: With Examples in Java',
      'Building Microservices: Designing Fine-Grained Systems',
      'Continuous Delivery: Reliable Software Releases',
      'The Linux Programming Interface: A Linux and UNIX System Programming Handbook',
      'Modern Operating Systems (4th Edition)',
      'Introduction to Information Retrieval',
      'Speech and Language Processing (3rd Draft Edition)',
      'Generative Deep Learning: Teaching Machines to Paint, Write, Compose',
      'Kubernetes Up and Running: Dive into Future of Infrastructure',
      'The Phoenix Project: A Novel about IT, DevOps, and Helping Your Business Win',
      'The Pragmatic Programmer: Your Journey To Mastery',
      'Working Effectively with Legacy Code',
      'Patterns of Enterprise Application Architecture',
      'Test Driven Development: By Example',
      'Release It!: Design and Deploy Production-Ready Software',
      'Practical Object-Oriented Design in Ruby',
      'Head First Design Patterns: Building Extensible Software',
      'Cracking the Coding Interview: 189 Programming Questions',
      'Enterprise Integration Patterns: Designing, Building, and Deploying Messaging',
      'Zero Trust Networks: Building Secure Systems in Untrusted Networks',
      'Cryptography Engineering: Design Principles and Practical Applications',
      'Concurrency in Go: Tools and Techniques for Developers',
    ];

    for (int i = 0; i < sampleTitles.length; i++) {
      final index = 11 + i;
      final category = categories[i % categories.length];
      final title = sampleTitles[i];
      final isbn = '978-0${100000000 + index}';
      final copies = 3 + (i % 6);
      final avail = (copies > 4) ? copies - 2 : copies - 1;

      books.add({
        'id': 'book_$index',
        'isbn': isbn,
        'title': title,
        'author': 'Academic Fellow & Research Faculty',
        'category': category,
        'shelf_location':
            'FLOOR-${(i % 3) + 1} / AISLE-${String.fromCharCode(65 + (i % 5))} / BAY-${(i % 12) + 1}',
        'total_copies': copies,
        'available_copies': avail,
        'is_reserved': (i % 7 == 0) ? 1 : 0,
        'abstract':
            'A peer-reviewed academic resource exploring $title with state-of-the-art methodology, benchmark analysis, and rigorous computational verification.',
        'table_of_contents': jsonEncode([
          'Chapter 1: Foundational Principles & Problem Formulation',
          'Chapter 2: Architectural Taxonomy & Core Abstractions',
          'Chapter 3: Empirical Benchmarking & Systemic Verification',
          'Chapter 4: Scalability Bounds & Future Trajectories',
        ]),
        'cover_asset': category == 'AI & ML'
            ? 'assets/images/book_applied_ai.png'
            : category == 'Cloud & Security'
            ? 'assets/images/book_distributed_databases.png'
            : category == 'Systems & Architecture'
            ? 'assets/images/book_mobile_systems.png'
            : 'assets/images/book_clean_architecture.png',
      });
    }

    return books;
  }

  static Future<void> _seedExamPasses(Database db) async {
    const studentId = 'CTZ-2024-8842';
    const studentName = 'Safeer Hussain';

    final passes = [
      {
        'id': 'exam_pass_001',
        'student_id': studentId,
        'student_name': studentName,
        'course_code': 'CS-401',
        'course_title': 'Advanced Distributed Systems',
        'exam_type': 'Final Comprehensive Examination',
        'exam_date': DateTime(2026, 11, 18, 9, 0).millisecondsSinceEpoch,
        'duration_minutes': 180,
        'hall_name': 'Turing Hall',
        'seat_row': 'C',
        'seat_number': 14,
        'desk_number': 'TH-C14',
        'is_verified': 1,
        'is_reminder_set': 1,
        'reminder_lead_minutes': 60,
        'invigilator_name': 'Dr. Alan Vance',
        'instructions': jsonEncode([
          'Candidate must present official physical student ID card along with optical admission pass.',
          'No programmable calculators, cellular devices, or wearable electronics allowed at candidate desk.',
          'Candidates must occupy assigned desk TH-C14 at least 15 minutes before exam commencement.',
        ]),
      },
      {
        'id': 'exam_pass_002',
        'student_id': studentId,
        'student_name': studentName,
        'course_code': 'CS-420',
        'course_title': 'Applied Machine Learning & Neural Systems',
        'exam_type': 'Midterm Laboratory Evaluation',
        'exam_date': DateTime(2026, 11, 20, 14, 0).millisecondsSinceEpoch,
        'duration_minutes': 120,
        'hall_name': 'Hopper Auditorium',
        'seat_row': 'E',
        'seat_number': 8,
        'desk_number': 'HA-E08',
        'is_verified': 0,
        'is_reminder_set': 0,
        'reminder_lead_minutes': 60,
        'invigilator_name': 'Prof. Margaret Hamilton',
        'instructions': jsonEncode([
          'Laboratory terminals are pre-configured in strict sandboxed mode with zero internet routing.',
          'All model checkpoints and code solutions must be committed to the offline university repository before time expires.',
          'Maintain complete silence and raise hand for proctor assistance.',
        ]),
      },
      {
        'id': 'exam_pass_003',
        'student_id': studentId,
        'student_name': studentName,
        'course_code': 'SE-450',
        'course_title': 'Autonomous Mobile Architectures',
        'exam_type': 'Final Theory Examination',
        'exam_date': DateTime(2026, 11, 23, 9, 0).millisecondsSinceEpoch,
        'duration_minutes': 180,
        'hall_name': 'Turing Hall',
        'seat_row': 'B',
        'seat_number': 6,
        'desk_number': 'TH-B06',
        'is_verified': 1,
        'is_reminder_set': 1,
        'reminder_lead_minutes': 120,
        'invigilator_name': 'Dr. Barbara Liskov',
        'instructions': jsonEncode([
          'Closed-book examination covering concurrency models, state isolation, and native platform channels.',
          'Clear plastic pencil cases only; unauthorized paper notes will result in immediate disqualification.',
          'Exit from examination hall permitted only after first 60 minutes of session.',
        ]),
      },
      {
        'id': 'exam_pass_004',
        'student_id': studentId,
        'student_name': studentName,
        'course_code': 'CS-490',
        'course_title': 'Senior Capstone Defense & Cloud Systems',
        'exam_type': 'Oral Defense & System Validation',
        'exam_date': DateTime(2026, 11, 26, 11, 30).millisecondsSinceEpoch,
        'duration_minutes': 90,
        'hall_name': 'Hopper Auditorium',
        'seat_row': 'A',
        'seat_number': 4,
        'desk_number': 'HA-A04',
        'is_verified': 0,
        'is_reminder_set': 0,
        'reminder_lead_minutes': 60,
        'invigilator_name': 'Prof. Donald Knuth',
        'instructions': jsonEncode([
          'Presentation slides and architectural proof-of-concept system demonstration to evaluation jury.',
          'Q&A defense session follows immediately after the 30-minute system walkthrough.',
          'Formal academic dress code required for all graduating senior candidates.',
        ]),
      },
    ];

    for (final pass in passes) {
      final checksum = ExamCryptography.generateChecksum(
        passId: pass['id'] as String,
        studentId: pass['student_id'] as String,
        courseCode: pass['course_code'] as String,
        hallName: pass['hall_name'] as String,
        deskNumber: pass['desk_number'] as String,
        examTimestamp: pass['exam_date'] as int,
      );

      final opticalToken = ExamCryptography.generateOpticalPayload(
        passId: pass['id'] as String,
        studentId: pass['student_id'] as String,
        courseCode: pass['course_code'] as String,
        deskNumber: pass['desk_number'] as String,
        checksum: checksum,
      );

      await db.insert('exam_hall_passes', {
        ...pass,
        'optical_token': opticalToken,
        'cryptographic_checksum': checksum,
      });
    }
  }

  static Future<void> _seedStudyRooms(Database db) async {
    final rooms = [
      // Floor 1: Innovation Commons
      {
        'id': 'sr_101',
        'name': 'Turing Innovation Pod 101',
        'floor': 1,
        'capacity': 4,
        'amenities': jsonEncode([
          '4K Presentation Display',
          'Whiteboard Wall',
          'Type-C Fast Charging',
        ]),
        'is_available': 1,
        'photo_asset': 'assets/images/study_room_turing.png',
      },
      {
        'id': 'sr_102',
        'name': 'Lovelace Brainstorm Suite 102',
        'floor': 1,
        'capacity': 8,
        'amenities': jsonEncode([
          'Interactive Smartboard',
          'Video Conference Rig',
          'Acoustic Baffles',
          'Whiteboard Wall',
        ]),
        'is_available': 1,
        'photo_asset': 'assets/images/study_room_lovelace.png',
      },
      {
        'id': 'sr_103',
        'name': 'Shannon Data Lab 103',
        'floor': 1,
        'capacity': 6,
        'amenities': jsonEncode([
          'Dual Monitor Station',
          'Gigabit Ethernet',
          'Power Hub',
        ]),
        'is_available': 1,
        'photo_asset': 'assets/images/study_room_shannon.png',
      },

      // Floor 2: Software Engineering & Algorithms
      {
        'id': 'sr_201',
        'name': 'Dijkstra Algorithm Pod 201',
        'floor': 2,
        'capacity': 4,
        'amenities': jsonEncode([
          'Whiteboard Wall',
          '4K Presentation Display',
          'Ergonomic Chairs',
        ]),
        'is_available': 1,
        'photo_asset': 'assets/images/study_room_dijkstra.png',
      },
      {
        'id': 'sr_202',
        'name': 'Knuth Systems Thinktank 202',
        'floor': 2,
        'capacity': 10,
        'amenities': jsonEncode([
          'Projector 120-inch',
          'Microphone Array',
          'Surround Audio',
          'Dual Whiteboard',
        ]),
        'is_available': 1,
        'photo_asset': 'assets/images/study_room_knuth.png',
      },
      {
        'id': 'sr_203',
        'name': 'Hopper Compiler Lab 203',
        'floor': 2,
        'capacity': 6,
        'amenities': jsonEncode([
          'Whiteboard Wall',
          'Video Conference Rig',
          'Ergonomic Chairs',
        ]),
        'is_available': 1,
        'photo_asset': 'assets/images/study_room_hopper.png',
      },

      // Floor 3: Architecture & Distributed Systems
      {
        'id': 'sr_301',
        'name': 'Lamport Consensus Hub 301',
        'floor': 3,
        'capacity': 6,
        'amenities': jsonEncode([
          'Whiteboard Wall',
          'Ultra-wide Presentation Monitor',
          'Type-C Fast Charging',
        ]),
        'is_available': 1,
        'photo_asset': 'assets/images/study_room_lamport.png',
      },
      {
        'id': 'sr_302',
        'name': 'Hamilton Mission Room 302',
        'floor': 3,
        'capacity': 12,
        'amenities': jsonEncode([
          '4K Quad-Display Wall',
          'Dual Video Conference Rig',
          'Podium Microphone',
          'Soundproof Paneling',
        ]),
        'is_available': 1,
        'photo_asset': 'assets/images/study_room_hamilton.png',
      },
      {
        'id': 'sr_303',
        'name': 'Von Neumann Quantum Cell 303',
        'floor': 3,
        'capacity': 4,
        'amenities': jsonEncode([
          'Whiteboard Wall',
          'High-Power Workstations',
          'Wireless Casting',
        ]),
        'is_available': 1,
        'photo_asset': 'assets/images/study_room_neumann.png',
      },

      // Floor 4: Executive Research & Postgraduate
      {
        'id': 'sr_401',
        'name': 'Chomsky Linguistics Alcove 401',
        'floor': 4,
        'capacity': 4,
        'amenities': jsonEncode([
          'Acoustic Quiet Pod',
          'Whiteboard Wall',
          'Ergonomic Recliners',
        ]),
        'is_available': 1,
        'photo_asset': 'assets/images/study_room_chomsky.png',
      },
      {
        'id': 'sr_402',
        'name': 'Gödel Logic Observatory 402',
        'floor': 4,
        'capacity': 8,
        'amenities': jsonEncode([
          'Panoramic City View',
          'Interactive Smartboard',
          'Polycom Conference Hub',
          'Espresso Bar Access',
        ]),
        'is_available': 1,
        'photo_asset': 'assets/images/study_room_godel.png',
      },
    ];

    for (final r in rooms) {
      await db.insert('study_rooms', r);
    }
  }

  static Future<void> _seedStudyRoomBookings(Database db) async {
    final now = DateTime.now();

    final bookings = [
      {
        'id': 'sr_book_init_01',
        'room_id': 'sr_201',
        'room_name': 'Dijkstra Algorithm Pod 201',
        'floor': 2,
        'booked_by_id': 'CTZ-2026-8842',
        'booked_by_name': 'Safeer Hussain',
        'purpose': 'Distributed Systems & Raft Consensus Study',
        'start_time': now.add(const Duration(hours: 2)).millisecondsSinceEpoch,
        'end_time': now.add(const Duration(hours: 4)).millisecondsSinceEpoch,
        'attendees': jsonEncode([
          'safeer@cityzens.edu',
          'aris.thorne@cityzens.edu',
        ]),
        'created_at': now
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch,
        'status': 'confirmed',
      },
      {
        'id': 'sr_book_init_02',
        'room_id': 'sr_102',
        'room_name': 'Lovelace Brainstorm Suite 102',
        'floor': 1,
        'booked_by_id': 'CTZ-2026-4419',
        'booked_by_name': 'Elena Rostova',
        'purpose': 'Autonomous Robotics Team Sync',
        'start_time': now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
        'end_time': now.add(const Duration(hours: 3)).millisecondsSinceEpoch,
        'attendees': jsonEncode([
          'elena@cityzens.edu',
          'marcus@cityzens.edu',
          'chen@cityzens.edu',
        ]),
        'created_at': now
            .subtract(const Duration(hours: 5))
            .millisecondsSinceEpoch,
        'status': 'confirmed',
      },
    ];

    for (final b in bookings) {
      await db.insert('study_room_bookings', b);
    }
  }

  static Future<void> _seedFlashcards(Database db) async {
    final now = DateTime.now();

    // 1. Seed Decks
    final decks = [
      {
        'id': 'deck_algo',
        'title': 'Algorithms & Complexity',
        'category': 'Algorithms',
        'description': 'Asymptotic notations, graph traversals, dynamic programming, and amortized complexity.',
        'card_count': 4,
        'mastery_percentage': 75.0,
        'color_hex': '0xFF0D9488',
        'created_at': now
            .subtract(const Duration(days: 14))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'deck_dist',
        'title': 'Distributed Systems & Consensus',
        'category': 'Distributed Systems',
        'description': 'CAP theorem, Raft consensus, vector clocks, byzantine faults, and two-phase commits.',
        'card_count': 4,
        'mastery_percentage': 50.0,
        'color_hex': '0xFFD97706',
        'created_at': now
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'deck_mobile',
        'title': 'Mobile System Architecture',
        'category': 'Mobile Architecture',
        'description': 'Impeller rendering pipeline, VSync 120Hz frame scheduling, and Dart generational GC.',
        'card_count': 4,
        'mastery_percentage': 50.0,
        'color_hex': '0xFF2563EB',
        'created_at': now
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch,
      },
    ];

    for (final d in decks) {
      await db.insert('flashcard_decks', d);
    }

    // 2. Seed Flashcards
    final cards = [
      // Algorithms & Complexity Cards
      {
        'id': 'fc_algo_01',
        'deck_id': 'deck_algo',
        'front': 'What is the amortized time complexity of inserting into a dynamic array that doubles its capacity when full?',
        'back': 'O(1) amortized. Resizing costs O(N) but occurs only once every N insertions, so total work across N insertions is O(N).',
        'hint': 'Consider aggregate work across N append operations.',
        'repetitions': 3,
        'interval_days': 15,
        'ease_factor': 2.6,
        'next_review_date': now
            .add(const Duration(days: 8))
            .millisecondsSinceEpoch,
        'last_reviewed_date': now
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch,
        'mastery_level': 'mastered',
        'created_at': now
            .subtract(const Duration(days: 14))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'fc_algo_02',
        'deck_id': 'deck_algo',
        'front': 'What is the time complexity difference between Dijkstra algorithm with binary heap vs Fibonacci heap?',
        'back': 'Binary heap: O((V + E) log V). Fibonacci heap: O(E + V log V), since decrease-key is reduced to O(1) amortized.',
        'hint': 'Focus on the cost of decrease-key operations in dense graphs.',
        'repetitions': 2,
        'interval_days': 6,
        'ease_factor': 2.5,
        'next_review_date': now
            .subtract(const Duration(hours: 3))
            .millisecondsSinceEpoch,
        'last_reviewed_date': now
            .subtract(const Duration(days: 6))
            .millisecondsSinceEpoch,
        'mastery_level': 'reviewing',
        'created_at': now
            .subtract(const Duration(days: 14))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'fc_algo_03',
        'deck_id': 'deck_algo',
        'front': 'What two fundamental properties must an optimization problem exhibit to be solvable via Dynamic Programming?',
        'back': '1. Optimal Substructure (an optimal solution contains within it optimal solutions to subproblems). 2. Overlapping Subproblems (the recursive algorithm revisits the same subproblems repeatedly).',
        'hint':
            'Richard Bellman formulation for multistage decision processes.',
        'repetitions': 4,
        'interval_days': 28,
        'ease_factor': 2.7,
        'next_review_date': now
            .add(const Duration(days: 12))
            .millisecondsSinceEpoch,
        'last_reviewed_date': now
            .subtract(const Duration(days: 16))
            .millisecondsSinceEpoch,
        'mastery_level': 'mastered',
        'created_at': now
            .subtract(const Duration(days: 14))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'fc_algo_04',
        'deck_id': 'deck_algo',
        'front': 'What is the solution to recurrence T(n) = 2T(n/2) + Theta(n) according to Master Theorem?',
        'back': 'Theta(n log n). This matches Case 2 where log_b(a) = log_2(2) = 1 and f(n) = Theta(n^1).',
        'hint': 'Compare n^(log_b a) against f(n).',
        'repetitions': 1,
        'interval_days': 1,
        'ease_factor': 2.36,
        'next_review_date': now
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        'last_reviewed_date': now
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch,
        'mastery_level': 'learning',
        'created_at': now
            .subtract(const Duration(days: 14))
            .millisecondsSinceEpoch,
      },

      // Distributed Systems & Consensus Cards
      {
        'id': 'fc_dist_01',
        'deck_id': 'deck_dist',
        'front': 'Why does the CAP theorem state that consistency and availability cannot both be guaranteed during a network partition?',
        'back': 'In a network partition, communication between node groups is severed. A node must either reject updates (sacrificing Availability) or accept updates without consensus (sacrificing Consistency).',
        'hint': 'Consider the decision a node must make when isolated from other replicas.',
        'repetitions': 3,
        'interval_days': 12,
        'ease_factor': 2.5,
        'next_review_date': now
            .add(const Duration(days: 5))
            .millisecondsSinceEpoch,
        'last_reviewed_date': now
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch,
        'mastery_level': 'mastered',
        'created_at': now
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'fc_dist_02',
        'deck_id': 'deck_dist',
        'front': 'In the Raft consensus protocol, what is the role of terms and how are stale leaders handled?',
        'back': 'Terms act as logical clocks. Each RPC contains the sender term; if a leader or candidate receives a message with a higher term, it immediately steps down to follower.',
        'hint': 'Logical clock monotonic counters in RPC headers.',
        'repetitions': 2,
        'interval_days': 6,
        'ease_factor': 2.45,
        'next_review_date': now
            .subtract(const Duration(hours: 4))
            .millisecondsSinceEpoch,
        'last_reviewed_date': now
            .subtract(const Duration(days: 6))
            .millisecondsSinceEpoch,
        'mastery_level': 'reviewing',
        'created_at': now
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'fc_dist_03',
        'deck_id': 'deck_dist',
        'front': 'What causal ordering limitation of Lamport Timestamps is overcome by Vector Clocks?',
        'back': 'Lamport timestamps only guarantee: if a -> b, then L(a) < L(b). But L(a) < L(b) does not imply a -> b. Vector clocks provide an exact isomorphism: V(a) < V(b) if and only if a -> b.',
        'hint':
            'Differentiating concurrent events from causally dependent events.',
        'repetitions': 1,
        'interval_days': 1,
        'ease_factor': 2.5,
        'next_review_date': now
            .subtract(const Duration(hours: 2))
            .millisecondsSinceEpoch,
        'last_reviewed_date': now
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch,
        'mastery_level': 'learning',
        'created_at': now
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'fc_dist_04',
        'deck_id': 'deck_dist',
        'front': 'What is the primary vulnerability of Two-Phase Commit (2PC) during a coordinator failure?',
        'back': '2PC is a blocking protocol. If the coordinator crashes after nodes vote Yes but before Commit/Abort is broadcast, participants remain blocked holding locks indefinitely.',
        'hint': 'Blocking state when waiting for the coordinator decision.',
        'repetitions': 3,
        'interval_days': 14,
        'ease_factor': 2.6,
        'next_review_date': now
            .add(const Duration(days: 4))
            .millisecondsSinceEpoch,
        'last_reviewed_date': now
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
        'mastery_level': 'mastered',
        'created_at': now
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
      },

      // Mobile System Architecture Cards
      {
        'id': 'fc_mobile_01',
        'deck_id': 'deck_mobile',
        'front': 'Why does Flutter Impeller eliminate runtime shader compilation jank on Android and iOS?',
        'back': 'Impeller pre-compiles all pipeline shaders offline at application build time into an immutable shader cache, eliminating runtime SPIR-V/GLSL compilation during first draw.',
        'hint': 'Ahead-of-Time (AOT) graphics pipeline generation.',
        'repetitions': 2,
        'interval_days': 6,
        'ease_factor': 2.5,
        'next_review_date': now
            .add(const Duration(days: 2))
            .millisecondsSinceEpoch,
        'last_reviewed_date': now
            .subtract(const Duration(days: 4))
            .millisecondsSinceEpoch,
        'mastery_level': 'reviewing',
        'created_at': now
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'fc_mobile_02',
        'deck_id': 'deck_mobile',
        'front': 'How does Dart generational garbage collection optimize high-frequency Flutter widget reallocations?',
        'back': 'The Young Generation uses a semi-space copying scavenger. New short-lived widgets die almost instantly and are collected in parallel without scanning the large Old Generation heap.',
        'hint': 'Generational hypothesis and semi-space allocation.',
        'repetitions': 1,
        'interval_days': 1,
        'ease_factor': 2.4,
        'next_review_date': now
            .subtract(const Duration(hours: 5))
            .millisecondsSinceEpoch,
        'last_reviewed_date': now
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch,
        'mastery_level': 'learning',
        'created_at': now
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'fc_mobile_03',
        'deck_id': 'deck_mobile',
        'front': 'What is the exact function of hardware VSync pulses in mobile display refresh pipelines?',
        'back': 'VSync coordinates display swap-buffers with physical panel refresh (e.g. 120Hz = 8.3ms), preventing screen tearing and ensuring frame budget alignment.',
        'hint': 'Display controller synchronization with render engine rasterization.',
        'repetitions': 3,
        'interval_days': 14,
        'ease_factor': 2.6,
        'next_review_date': now
            .add(const Duration(days: 7))
            .millisecondsSinceEpoch,
        'last_reviewed_date': now
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch,
        'mastery_level': 'mastered',
        'created_at': now
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'fc_mobile_04',
        'deck_id': 'deck_mobile',
        'front': 'What performance advantage does Dart FFI offer over traditional Platform Channels?',
        'back': 'Dart FFI performs direct synchronous C-function calls in-process via memory pointers with zero serialization overhead, whereas Platform Channels require asynchronous binary message serialization.',
        'hint': 'Pointer dereference vs thread hopping and serialization.',
        'repetitions': 2,
        'interval_days': 6,
        'ease_factor': 2.55,
        'next_review_date': now
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        'last_reviewed_date': now
            .subtract(const Duration(days: 6))
            .millisecondsSinceEpoch,
        'mastery_level': 'reviewing',
        'created_at': now
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch,
      },
    ];

    for (final c in cards) {
      await db.insert('flashcards', c);
    }

    // 3. Seed 7 days of review history for retention analytics
    final reviews = [
      {
        'id': 'rev_01',
        'card_id': 'fc_algo_01',
        'deck_id': 'deck_algo',
        'quality': 5,
        'interval_days': 15,
        'ease_factor': 2.6,
        'reviewed_at': now
            .subtract(const Duration(days: 6))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'rev_02',
        'card_id': 'fc_algo_03',
        'deck_id': 'deck_algo',
        'quality': 4,
        'interval_days': 28,
        'ease_factor': 2.7,
        'reviewed_at': now
            .subtract(const Duration(days: 5))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'rev_03',
        'card_id': 'fc_dist_01',
        'deck_id': 'deck_dist',
        'quality': 5,
        'interval_days': 12,
        'ease_factor': 2.5,
        'reviewed_at': now
            .subtract(const Duration(days: 4))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'rev_04',
        'card_id': 'fc_dist_04',
        'deck_id': 'deck_dist',
        'quality': 4,
        'interval_days': 14,
        'ease_factor': 2.6,
        'reviewed_at': now
            .subtract(const Duration(days: 3))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'rev_05',
        'card_id': 'fc_mobile_01',
        'deck_id': 'deck_mobile',
        'quality': 4,
        'interval_days': 6,
        'ease_factor': 2.5,
        'reviewed_at': now
            .subtract(const Duration(days: 2))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'rev_06',
        'card_id': 'fc_mobile_03',
        'deck_id': 'deck_mobile',
        'quality': 5,
        'interval_days': 14,
        'ease_factor': 2.6,
        'reviewed_at': now
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch,
      },
    ];

    for (final r in reviews) {
      await db.insert('flashcard_reviews', r);
    }
  }

  static Future<void> _seedCafeteriaData(Database db) async {
    final now = DateTime.now();

    // 1. Seed Student Wallet for Safeer Hussain
    await db.insert('student_wallets', {
      'student_id': 'CTZ-2026-8842',
      'balance': 150.00,
      'reward_points': 320,
      'last_reloaded_at': now
          .subtract(const Duration(days: 3))
          .millisecondsSinceEpoch,
    });

    // 2. Seed Menu Items across Campus Dining Halls
    final menuItems = [
      // Turing Bistro (Floor 1)
      {
        'id': 'meal_tb_01',
        'name': 'Turing High-Protein Quinoa Bowl',
        'description': 'Warm organic quinoa, roasted chickpeas, avocado, baby spinach, tahini drizzle, and grilled tofu.',
        'category': 'Bowls',
        'price': 9.50,
        'calories': 580,
        'protein_g': 34.0,
        'carbs_g': 62.0,
        'fat_g': 18.0,
        'dietary_tags': jsonEncode([
          'Vegetarian',
          'Gluten-Free',
          'Halal',
          'High-Protein',
        ]),
        'dining_hall': 'Turing Bistro',
        'operational_hours': '07:30 - 20:00',
        'is_available': 1,
        'image_asset': 'assets/images/meal_quinoa_bowl.png',
      },
      {
        'id': 'meal_tb_02',
        'name': 'Alan Turing Sunrise Power Burrito',
        'description': 'Scrambled egg whites, black beans, Monterey Jack, roasted salsa, and seasoned lean turkey.',
        'category': 'Breakfast',
        'price': 7.25,
        'calories': 490,
        'protein_g': 28.0,
        'carbs_g': 45.0,
        'fat_g': 16.0,
        'dietary_tags': jsonEncode(['Halal', 'High-Protein']),
        'dining_hall': 'Turing Bistro',
        'operational_hours': '07:30 - 11:30',
        'is_available': 1,
        'image_asset': 'assets/images/meal_burrito.png',
      },
      {
        'id': 'meal_tb_03',
        'name': 'Nitro Cold Brew Energy Blend',
        'description': 'Slow-steeped micro-filtered Ethiopian beans infused with nitrogen for velvety microfoam.',
        'category': 'Beverages',
        'price': 4.50,
        'calories': 15,
        'protein_g': 1.0,
        'carbs_g': 2.0,
        'fat_g': 0.0,
        'dietary_tags': jsonEncode(['Vegan', 'Gluten-Free', 'Dairy-Free']),
        'dining_hall': 'Turing Bistro',
        'operational_hours': '07:30 - 20:00',
        'is_available': 1,
        'image_asset': 'assets/images/meal_nitro_coffee.png',
      },

      // Hopper Tech Eatery (Floor 2)
      {
        'id': 'meal_ht_01',
        'name': 'Hopper Mediterranean Chicken Wrap',
        'description': 'Flame-seared chicken breast, crisp cucumbers, pickled red onions, kalamata tzatziki in spinach tortilla.',
        'category': 'Lunch',
        'price': 8.50,
        'calories': 520,
        'protein_g': 38.0,
        'carbs_g': 48.0,
        'fat_g': 14.0,
        'dietary_tags': jsonEncode(['Halal', 'High-Protein']),
        'dining_hall': 'Hopper Tech Eatery',
        'operational_hours': '10:00 - 19:30',
        'is_available': 1,
        'image_asset': 'assets/images/meal_chicken_wrap.png',
      },
      {
        'id': 'meal_ht_02',
        'name': 'Grace Hopper Superfood Salmon Salad',
        'description': 'Wild-caught grilled salmon, shaved Tuscan kale, edamame, blueberries, chia seeds, citrus vinaigrette.',
        'category': 'Bowls',
        'price': 11.25,
        'calories': 460,
        'protein_g': 32.0,
        'carbs_g': 24.0,
        'fat_g': 22.0,
        'dietary_tags': jsonEncode(['Gluten-Free', 'Halal', 'High-Protein']),
        'dining_hall': 'Hopper Tech Eatery',
        'operational_hours': '11:00 - 19:30',
        'is_available': 1,
        'image_asset': 'assets/images/meal_salmon_salad.png',
      },
      {
        'id': 'meal_ht_03',
        'name': 'Vegan Yellow Lentil Sweet Potato Dal',
        'description': 'Simmered turmeric yellow lentils, tender sweet potatoes, coconut cream, served over jasmine rice.',
        'category': 'Lunch',
        'price': 7.00,
        'calories': 420,
        'protein_g': 18.0,
        'carbs_g': 68.0,
        'fat_g': 8.0,
        'dietary_tags': jsonEncode([
          'Vegan',
          'Vegetarian',
          'Gluten-Free',
          'Halal',
        ]),
        'dining_hall': 'Hopper Tech Eatery',
        'operational_hours': '11:00 - 19:30',
        'is_available': 1,
        'image_asset': 'assets/images/meal_lentil_dal.png',
      },

      // Lovelace Cafe & Espresso (Floor 3)
      {
        'id': 'meal_lc_01',
        'name': 'Lovelace Sourdough Avocado Poached Eggs',
        'description': 'Crusty artisan sourdough toast, smashed Hass avocados, two free-range poached eggs, micro-greens, chili flakes.',
        'category': 'Breakfast',
        'price': 7.75,
        'calories': 410,
        'protein_g': 19.0,
        'carbs_g': 38.0,
        'fat_g': 18.0,
        'dietary_tags': jsonEncode(['Vegetarian', 'High-Protein']),
        'dining_hall': 'Lovelace Cafe',
        'operational_hours': '08:00 - 18:00',
        'is_available': 1,
        'image_asset': 'assets/images/meal_avocado_toast.png',
      },
      {
        'id': 'meal_lc_02',
        'name': 'Ceremonial Matcha Oat Milk Latte',
        'description': 'First-harvest Uji Japanese green tea whisked with creamy steamed barista oat milk.',
        'category': 'Beverages',
        'price': 5.25,
        'calories': 140,
        'protein_g': 4.0,
        'carbs_g': 22.0,
        'fat_g': 3.5,
        'dietary_tags': jsonEncode(['Vegan', 'Vegetarian', 'Dairy-Free']),
        'dining_hall': 'Lovelace Cafe',
        'operational_hours': '08:00 - 18:00',
        'is_available': 1,
        'image_asset': 'assets/images/meal_matcha_latte.png',
      },
      {
        'id': 'meal_lc_03',
        'name': 'Artisanal Almond Butter Flaky Croissant',
        'description': 'French layered butter puff pastry filled with roasted California almond paste and powdered topping.',
        'category': 'Bakery',
        'price': 4.50,
        'calories': 360,
        'protein_g': 8.0,
        'carbs_g': 42.0,
        'fat_g': 18.0,
        'dietary_tags': jsonEncode(['Vegetarian']),
        'dining_hall': 'Lovelace Cafe',
        'operational_hours': '08:00 - 18:00',
        'is_available': 1,
        'image_asset': 'assets/images/meal_croissant.png',
      },
      {
        'id': 'meal_lc_04',
        'name': 'Organic Greek Yogurt Honey Berry Parfait',
        'description': 'Thick strained Greek yogurt, wild wildflower honey, fresh raspberries, blackberries, and granola.',
        'category': 'Breakfast',
        'price': 5.50,
        'calories': 290,
        'protein_g': 17.0,
        'carbs_g': 36.0,
        'fat_g': 6.0,
        'dietary_tags': jsonEncode(['Vegetarian', 'High-Protein']),
        'dining_hall': 'Lovelace Cafe',
        'operational_hours': '08:00 - 18:00',
        'is_available': 1,
        'image_asset': 'assets/images/meal_parfait.png',
      },
    ];

    for (final item in menuItems) {
      await db.insert('cafeteria_menu_items', item);
    }

    // 3. Seed Initial Pre-Orders for Safeer Hussain
    final orders = [
      {
        'id': 'ord_init_01',
        'order_number': 'ORD-8842-101',
        'student_id': 'CTZ-2026-8842',
        'student_name': 'Safeer Hussain',
        'dining_hall': 'Turing Bistro',
        'items_json': jsonEncode([
          {
            'item': menuItems[0],
            'quantity': 1,
            'special_instructions': 'Extra tahini dressing on side',
          },
          {
            'item': menuItems[2],
            'quantity': 1,
            'special_instructions': 'No sugar',
          },
        ]),
        'subtotal': 14.00,
        'discount': 0.0,
        'final_amount': 14.00,
        'total_calories': 595,
        'total_protein_g': 35.0,
        'total_carbs_g': 64.0,
        'total_fat_g': 18.0,
        'allergy_flags': jsonEncode(['Gluten-Free']),
        'special_instructions': 'Pack in recyclable containers please',
        'status': 'ready',
        'pickup_time': '12:30 PM',
        'payment_method': 'Meal Credits Debit',
        'nfc_token': 'NFC-TX-8842-99A1F4C2',
        'created_at': now
            .subtract(const Duration(hours: 3))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'ord_init_02',
        'order_number': 'ORD-8842-102',
        'student_id': 'CTZ-2026-8842',
        'student_name': 'Safeer Hussain',
        'dining_hall': 'Lovelace Cafe',
        'items_json': jsonEncode([
          {
            'item': menuItems[6],
            'quantity': 1,
            'special_instructions': 'Warm poached eggs',
          },
          {
            'item': menuItems[7],
            'quantity': 1,
            'special_instructions': 'Extra hot oat milk',
          },
        ]),
        'subtotal': 13.00,
        'discount': 0.0,
        'final_amount': 13.00,
        'total_calories': 550,
        'total_protein_g': 23.0,
        'total_carbs_g': 60.0,
        'total_fat_g': 21.5,
        'allergy_flags': jsonEncode(['Vegetarian']),
        'special_instructions': 'Leave at pickup counter slot A2',
        'status': 'confirmed',
        'pickup_time': '02:15 PM',
        'payment_method': 'NFC Tap-to-Pay',
        'nfc_token': 'NFC-TX-8842-3B7D8110',
        'created_at': now
            .subtract(const Duration(minutes: 45))
            .millisecondsSinceEpoch,
      },
    ];

    for (final o in orders) {
      await db.insert('cafeteria_orders', o);
    }
  }

  static Future<void> _seedParkingData(Database db) async {
    final now = DateTime.now();

    // 1. Seed Parking Zones
    final zones = [
      {
        'id': 'zone_north_deck',
        'name': 'North Structure Multilevel Deck',
        'campus_area': 'North Gate / Engineering Complex',
        'total_spots': 260,
        'occupied_spots': 185,
        'total_ev_spots': 24,
        'occupied_ev_spots': 16,
        'hourly_rate': 1.50,
        'operational_hours': '06:00 - 23:00',
        'is_covered': 1,
        'charger_types': jsonEncode([
          'DC Fast 50kW (CCS)',
          'Level 2 7.2kW (J1772)',
        ]),
      },
      {
        'id': 'zone_south_lot',
        'name': 'South STEM Surface Lot',
        'campus_area': 'South Quad / Natural Sciences',
        'total_spots': 180,
        'occupied_spots': 142,
        'total_ev_spots': 12,
        'occupied_ev_spots': 10,
        'hourly_rate': 1.00,
        'operational_hours': '07:00 - 22:00',
        'is_covered': 0,
        'charger_types': jsonEncode(['Level 2 7.2kW (J1772)']),
      },
      {
        'id': 'zone_ev_plaza',
        'name': 'Innovation Hub EV Supercharging Plaza',
        'campus_area': 'West Campus / Research Center',
        'total_spots': 48,
        'occupied_spots': 31,
        'total_ev_spots': 48,
        'occupied_ev_spots': 31,
        'hourly_rate': 2.25,
        'operational_hours': '24 Hours Open',
        'is_covered': 1,
        'charger_types': jsonEncode([
          'Tesla NACS / CCS 150kW',
          'DC Fast 50kW (CCS)',
        ]),
      },
    ];

    for (final z in zones) {
      await db.insert('parking_zones', z);
    }

    // 2. Seed Student Parking Permit for Safeer Hussain
    await db.insert('parking_permits', {
      'id': 'pmt_8842_01',
      'student_id': 'CTZ-2026-8842',
      'student_name': 'Safeer Hussain',
      'vehicle_plate': 'ABC-8842',
      'vehicle_model': 'Tesla Model 3 / Pearl White',
      'permit_tier': 'EV All-Access Pass',
      'valid_from': now
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
      'valid_until': now.add(const Duration(days: 120)).millisecondsSinceEpoch,
      'is_active': 1,
      'assigned_zone': 'All Campus Lots',
      'rfid_token': 'RFID-PK-8842-E93B17C8',
      'barcode_payload': 'CTZ-PRK-8842-ABC8842',
    });

    // 3. Seed Initial EV Charging Reservation
    await db.insert('ev_charging_reservations', {
      'id': 'ev_res_init_01',
      'student_id': 'CTZ-2026-8842',
      'student_name': 'Safeer Hussain',
      'zone_id': 'zone_north_deck',
      'zone_name': 'North Structure Multilevel Deck',
      'station_id': 'ST-04',
      'charger_type': 'DC Fast 50kW (CCS)',
      'slot_time': '14:30 - 15:30',
      'target_battery_percent': 85,
      'estimated_energy_kwh': 32.5,
      'cost_credits': 4.50,
      'queue_token': 'EV-QUEUE-#04',
      'status': 'confirmed',
      'created_at': now
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch,
    });
  }

  static Future<void> _seedTimetableSlots(Database db) async {
    final slots = [
      // 1. CS-401 (Enrolled Section A: Mon & Wed 09:00 - 10:30)
      {
        'id': 'slot_cs401_sec_a_mon',
        'course_id': 'crs_01',
        'course_code': 'CS-401',
        'course_title': 'Distributed Systems & Cloud Computing',
        'section_name': 'Section A',
        'instructor': 'Dr. Aris Thorne',
        'room': 'Alan Turing Hall 302',
        'day_of_week': 1, // Mon
        'start_time_minutes': 540, // 09:00
        'end_time_minutes': 630, // 10:30
        'is_lab': 0,
        'is_enrolled': 1,
      },
      {
        'id': 'slot_cs401_sec_a_wed',
        'course_id': 'crs_01',
        'course_code': 'CS-401',
        'course_title': 'Distributed Systems & Cloud Computing',
        'section_name': 'Section A',
        'instructor': 'Dr. Aris Thorne',
        'room': 'Alan Turing Hall 302',
        'day_of_week': 3, // Wed
        'start_time_minutes': 540, // 09:00
        'end_time_minutes': 630, // 10:30
        'is_lab': 0,
        'is_enrolled': 1,
      },
      // CS-401 Alternative (Section B: Tue & Thu 14:00 - 15:30)
      {
        'id': 'slot_cs401_sec_b_tue',
        'course_id': 'crs_01',
        'course_code': 'CS-401',
        'course_title': 'Distributed Systems & Cloud Computing',
        'section_name': 'Section B (Afternoon)',
        'instructor': 'Dr. Aris Thorne',
        'room': 'Alan Turing Hall 302',
        'day_of_week': 2, // Tue
        'start_time_minutes': 840, // 14:00
        'end_time_minutes': 930, // 15:30
        'is_lab': 0,
        'is_enrolled': 0,
      },
      {
        'id': 'slot_cs401_sec_b_thu',
        'course_id': 'crs_01',
        'course_code': 'CS-401',
        'course_title': 'Distributed Systems & Cloud Computing',
        'section_name': 'Section B (Afternoon)',
        'instructor': 'Dr. Aris Thorne',
        'room': 'Alan Turing Hall 302',
        'day_of_week': 4, // Thu
        'start_time_minutes': 840, // 14:00
        'end_time_minutes': 930, // 15:30
        'is_lab': 0,
        'is_enrolled': 0,
      },

      // 2. CS-405 (Enrolled Section A: Tue & Thu 11:00 - 12:30 + Fri Lab)
      {
        'id': 'slot_cs405_sec_a_tue',
        'course_id': 'crs_02',
        'course_code': 'CS-405',
        'course_title': 'Advanced Mobile Architecture',
        'section_name': 'Section A',
        'instructor': 'Prof. Evelyn Vance',
        'room': 'Grace Hopper Hall 101',
        'day_of_week': 2, // Tue
        'start_time_minutes': 660, // 11:00
        'end_time_minutes': 750, // 12:30
        'is_lab': 0,
        'is_enrolled': 1,
      },
      {
        'id': 'slot_cs405_sec_a_thu',
        'course_id': 'crs_02',
        'course_code': 'CS-405',
        'course_title': 'Advanced Mobile Architecture',
        'section_name': 'Section A',
        'instructor': 'Prof. Evelyn Vance',
        'room': 'Grace Hopper Hall 101',
        'day_of_week': 4, // Thu
        'start_time_minutes': 660, // 11:00
        'end_time_minutes': 750, // 12:30
        'is_lab': 0,
        'is_enrolled': 1,
      },
      {
        'id': 'slot_cs405_lab_a_fri',
        'course_id': 'crs_02',
        'course_code': 'CS-405',
        'course_title': 'Advanced Mobile Architecture Lab',
        'section_name': 'Lab Bay A1',
        'instructor': 'Dr. Marcus Brody',
        'room': 'Engineering Lab 4B',
        'day_of_week': 5, // Fri
        'start_time_minutes': 600, // 10:00
        'end_time_minutes': 720, // 12:00
        'is_lab': 1,
        'is_enrolled': 1,
      },

      // 3. SE-420 (Enrolled Section A: Wed 09:30 - 11:00 -> CONFLICTS with CS-401 on Wed 09:00 - 10:30!)
      {
        'id': 'slot_se420_sec_a_wed',
        'course_id': 'crs_04',
        'course_code': 'SE-420',
        'course_title': 'Formal Methods & Verification',
        'section_name': 'Section A',
        'instructor': 'Dr. Donald Knuth',
        'room': 'Shannon Tower 404',
        'day_of_week': 3, // Wed
        'start_time_minutes': 570, // 09:30 (overlaps by 60 min)
        'end_time_minutes': 660, // 11:00
        'is_lab': 0,
        'is_enrolled': 1,
      },
      // SE-420 Non-conflicting alternative (Section B: Wed 14:00 - 15:30)
      {
        'id': 'slot_se420_sec_b_wed',
        'course_id': 'crs_04',
        'course_code': 'SE-420',
        'course_title': 'Formal Methods & Verification',
        'section_name': 'Section B (Afternoon)',
        'instructor': 'Dr. Donald Knuth',
        'room': 'Shannon Tower 404',
        'day_of_week': 3, // Wed
        'start_time_minutes': 840, // 14:00
        'end_time_minutes': 930, // 15:30
        'is_lab': 0,
        'is_enrolled': 0,
      },

      // 4. SEC-430 (Enrolled Section A: Mon & Wed 11:30 - 13:00)
      {
        'id': 'slot_sec430_sec_a_mon',
        'course_id': 'crs_05',
        'course_code': 'SEC-430',
        'course_title': 'Applied Cryptography & Zero-Knowledge Proofs',
        'section_name': 'Section A',
        'instructor': 'Prof. Adi Shamir',
        'room': 'Lovelace Wing 201',
        'day_of_week': 1, // Mon
        'start_time_minutes': 690, // 11:30
        'end_time_minutes': 780, // 13:00
        'is_lab': 0,
        'is_enrolled': 1,
      },
      {
        'id': 'slot_sec430_sec_a_wed',
        'course_id': 'crs_05',
        'course_code': 'SEC-430',
        'course_title': 'Applied Cryptography & Zero-Knowledge Proofs',
        'section_name': 'Section A',
        'instructor': 'Prof. Adi Shamir',
        'room': 'Lovelace Wing 201',
        'day_of_week': 3, // Wed
        'start_time_minutes': 690, // 11:30
        'end_time_minutes': 780, // 13:00
        'is_lab': 0,
        'is_enrolled': 1,
      },

      // 5. CS-410 (Elective: Thu 09:00 - 10:30 & Fri Lab 14:00 - 16:00)
      {
        'id': 'slot_cs410_sec_a_thu',
        'course_id': 'crs_06',
        'course_code': 'CS-410',
        'course_title': 'Autonomous Agents & Reinforcement Learning',
        'section_name': 'Section A',
        'instructor': 'Dr. Demis Hassabis',
        'room': 'DeepMind Complex 101',
        'day_of_week': 4, // Thu
        'start_time_minutes': 540, // 09:00
        'end_time_minutes': 630, // 10:30
        'is_lab': 0,
        'is_enrolled': 0,
      },
      {
        'id': 'slot_cs410_lab_a_fri',
        'course_id': 'crs_06',
        'course_code': 'CS-410',
        'course_title': 'Autonomous Agents Simulation Lab',
        'section_name': 'Lab Bay B',
        'instructor': 'Dr. Demis Hassabis',
        'room': 'DeepMind Complex Lab 2',
        'day_of_week': 5, // Fri
        'start_time_minutes': 840, // 14:00
        'end_time_minutes': 960, // 16:00
        'is_lab': 1,
        'is_enrolled': 0,
      },
    ];

    for (final s in slots) {
      await db.insert('timetable_slots', s);
    }
  }
}
