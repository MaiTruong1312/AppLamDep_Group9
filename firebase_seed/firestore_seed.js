// firebase_seed.js
const admin = require('firebase-admin');
const path = require('path');

// ================== CONFIGURATION ==================
const CONFIG = {
  projectId: 'applamdep-ffa8e',
  serviceAccountPath: path.join(__dirname, 'serviceAccountKey.json'), // Đảm bảo file này tồn tại
};

// ================== INITIALIZE FIREBASE ==================
function initializeFirebase() {
  try {
    const serviceAccount = require(CONFIG.serviceAccountPath);
    // Kiểm tra xem app đã khởi tạo chưa để tránh lỗi "Default app already exists"
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: CONFIG.projectId
      });
    }
    console.log(`✅ Đã kết nối Firebase: ${CONFIG.projectId}`);
    return admin.firestore();
  } catch (error) {
    console.error('❌ Lỗi khi initialize Firebase:', error.message);
    process.exit(1);
  }
}

// ================== CẤU TRÚC COLLECTIONS CẦN THIẾT ==================
const COLLECTIONS_STRUCTURE = {
  // 1. BẢNG SERVICES - Dịch vụ (Đã nâng cấp)
  services: {
    fields: {
      id: 'string',
      storeIds: 'array', // UPDATE: Dùng mảng để 1 dịch vụ thuộc nhiều store
      name: 'string',
      description: 'string',
      price: 'number',
      duration: 'number',
      category: 'string', // 'care', 'spa', 'nail_service', 'additional_service'
      isActive: 'boolean',
      imageUrl: 'string',
      requiresNailDesign: 'boolean',
      position: 'number',
      createdAt: 'timestamp',
      updatedAt: 'timestamp'
    },
    sampleData: [
      // --- NHÓM CHĂM SÓC (CARE) ---
      {
        id: 'basic_care_cuticle',
        storeIds: ['1', '2', '3', '4', '5'], // Áp dụng cho tất cả store
        name: 'Cắt da tay/chân',
        description: 'Làm sạch da thừa quanh móng, tạo form móng gọn gàng',
        price: 50000,
        duration: 30,
        category: 'care',
        isActive: true,
        imageUrl: 'assets/images/services/cuticle.png',
        requiresNailDesign: false,
        position: 1
      },
      {
        id: 'remove_gel',
        storeIds: ['1', '2', '3', '4', '5'],
        name: 'Tháo sơn Gel/Bột',
        description: 'Tháo lớp sơn/bột cũ kỹ, làm sạch bề mặt móng an toàn',
        price: 30000,
        duration: 20,
        category: 'care',
        isActive: true,
        imageUrl: 'assets/images/services/remove.png',
        requiresNailDesign: false,
        position: 2
      },
      {
        id: 'heel_scrub',
        storeIds: ['1', '3'],
        name: 'Chà gót chân',
        description: 'Loại bỏ da chết gót chân, giúp chân mềm mại',
        price: 100000,
        duration: 30,
        category: 'care',
        isActive: true,
        imageUrl: 'assets/images/services/heel.png',
        requiresNailDesign: false,
        position: 3
      },

      // --- NHÓM SƠN & TẠO KIỂU (NAIL_SERVICE) ---
      {
        id: 'gel_color',
        storeIds: ['1', '2', '3', '4', '5'],
        name: 'Sơn Gel Màu',
        description: 'Sơn gel màu trơn cao cấp, bền màu 3-4 tuần',
        price: 120000,
        duration: 45,
        category: 'nail_service',
        isActive: true,
        imageUrl: 'assets/images/services/gel_color.png',
        requiresNailDesign: false,
        position: 4
      },

      // --- NHÓM DỊCH VỤ THÊM / KỸ THUẬT CAO (ADDITIONAL_SERVICE) ---
      {
        id: 'nail_tips_full',
        storeIds: ['1', '2'],
        name: 'Úp móng nghệ thuật',
        description: 'Úp móng giả full ngón, form chuẩn tự nhiên',
        price: 150000,
        duration: 60,
        category: 'additional_service',
        isActive: true,
        imageUrl: 'assets/images/services/tips.png',
        requiresNailDesign: true,
        position: 5
      },
      {
        id: 'nail_art_design',
        storeIds: ['1', '2', '3', '4', '5'],
        name: 'Vẽ Nail Design',
        description: 'Vẽ họa tiết theo yêu cầu (giá tùy mẫu)',
        price: 50000,
        duration: 30,
        category: 'additional_service',
        isActive: true,
        imageUrl: 'assets/images/services/nail_art.png',
        requiresNailDesign: true,
        position: 6
      },
      {
        id: 'crystal_addon',
        storeIds: ['1', '2', '3', '4', '5'],
        name: 'Đính Đá Pha Lê',
        description: 'Đính đá khối/đá chân bằng sáng lấp lánh',
        price: 5000, // Giá từ
        duration: 15,
        category: 'additional_service',
        isActive: true,
        imageUrl: 'assets/images/services/crystal.png',
        requiresNailDesign: true,
        position: 7
      },

      // --- NHÓM SPA & THƯ GIÃN (SPA) ---
      {
        id: 'hand_massage',
        storeIds: ['1', '4'],
        name: 'Massage tay thư giãn',
        description: 'Massage với tinh dầu và kem dưỡng ẩm sâu',
        price: 150000,
        duration: 30,
        category: 'spa',
        isActive: true,
        imageUrl: 'assets/images/services/massage.png',
        requiresNailDesign: false,
        position: 8
      }
    ]
  },

  // 2. BẢNG STORE_WORKING_HOURS
  store_working_hours: {
    // Giữ nguyên như cũ
    fields: {
      id: 'string',
      storeId: 'string',
      dayOfWeek: 'number',
      isOpen: 'boolean',
      openTime: 'string',
      closeTime: 'string',
      createdAt: 'timestamp',
      updatedAt: 'timestamp'
    },
    sampleData: [
      { id: 'store1_mon', storeId: '1', dayOfWeek: 1, isOpen: true, openTime: '09:00', closeTime: '20:00' },
      { id: 'store1_tue', storeId: '1', dayOfWeek: 2, isOpen: true, openTime: '09:00', closeTime: '20:00' },
      { id: 'store1_wed', storeId: '1', dayOfWeek: 3, isOpen: true, openTime: '09:00', closeTime: '20:00' },
      { id: 'store1_thu', storeId: '1', dayOfWeek: 4, isOpen: true, openTime: '09:00', closeTime: '20:00' },
      { id: 'store1_fri', storeId: '1', dayOfWeek: 5, isOpen: true, openTime: '09:00', closeTime: '20:00' },
      { id: 'store1_sat', storeId: '1', dayOfWeek: 6, isOpen: true, openTime: '09:00', closeTime: '21:00' },
      { id: 'store1_sun', storeId: '1', dayOfWeek: 0, isOpen: true, openTime: '09:00', closeTime: '21:00' }
    ]
  },

  // 3. BẢNG STORE_TECHNICIANS
  store_technicians: {
    // Giữ nguyên cấu trúc
    fields: {
      id: 'string',
      storeId: 'string',
      name: 'string',
      rating: 'number',
      isAvailable: 'boolean',
      createdAt: 'timestamp',
      updatedAt: 'timestamp'
    },
    sampleData: [
      {
        id: 'tech1',
        storeId: '1',
        name: 'Nguyễn Thị Mai',
        rating: 4.8,
        isAvailable: true,
        avatarUrl: 'https://i.pravatar.cc/150?img=5',
        specialty: ['nail_art', 'gel_nails']
      },
      {
        id: 'tech2',
        storeId: '1',
        name: 'Trần Văn An',
        rating: 4.9,
        isAvailable: true,
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
        specialty: ['care', 'massage']
      }
    ]
  }
};

// ================== HÀM TẠO COLLECTION ==================
async function createCollection(db, collectionName, structure) {
  try {
    console.log(`\n📁 Đang xử lý collection: ${collectionName}...`);

    // Tạo sample data mới hoặc update
    if (structure.sampleData && structure.sampleData.length > 0) {
      const batch = db.batch();
      let count = 0;

      structure.sampleData.forEach((data) => {
        // Sử dụng ID có sẵn hoặc tạo mới
        const docId = data.id || `${collectionName}_${count}`;
        const docRef = db.collection(collectionName).doc(docId);

        const docData = {
          ...data,
          createdAt: admin.firestore.FieldValue.serverTimestamp(), // Luôn update timestamp
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        // Dùng set với merge: true để không ghi đè hoàn toàn nếu đã có,
        // nhưng vẫn cập nhật các trường mới
        batch.set(docRef, docData, { merge: true });
        count++;
      });

      await batch.commit();
      console.log(`   ✅ Đã cập nhật/tạo ${count} documents trong ${collectionName}`);
    }
  } catch (error) {
    console.error(`   ❌ Lỗi khi tạo ${collectionName}:`, error.message);
  }
}

// ================== HÀM MIGRATE DỮ LIỆU CŨ ==================
async function migrateServiceData(db) {
  console.log('\n🔄 Đang kiểm tra và migrate dữ liệu Services cũ...');
  try {
    const servicesRef = db.collection('services');
    const snapshot = await servicesRef.get();
    const batch = db.batch();
    let migrateCount = 0;

    snapshot.docs.forEach(doc => {
      const data = doc.data();

      // Nếu có storeId (string) mà chưa có storeIds (array)
      if (data.storeId && !data.storeIds) {
        batch.update(doc.ref, {
          storeIds: [data.storeId], // Chuyển string cũ thành mảng 1 phần tử
          // storeId: admin.firestore.FieldValue.delete() // Bỏ comment nếu muốn xóa trường cũ luôn
        });
        migrateCount++;
      }

      // Nếu chưa có category, gán mặc định
      if (!data.category) {
        batch.update(doc.ref, { category: 'nail_service' });
      }
    });

    if (migrateCount > 0) {
      await batch.commit();
      console.log(`   ✅ Đã migrate ${migrateCount} dịch vụ từ storeId -> storeIds`);
    } else {
      console.log('   ℹ️  Dữ liệu đã chuẩn, không cần migrate.');
    }

  } catch (error) {
    console.error('   ❌ Lỗi migrate data:', error.message);
  }
}

// ================== HÀM SINH BOOKING SLOTS (CHO TẤT CẢ STORE) ==================
async function generateBookingSlots(db) {
  console.log('\n⏰ Đang tạo booking slots cho 7 ngày tới...');
  try {
    // Lấy tất cả active stores
    const storesSnapshot = await db.collection('stores')
        .where('is_open', '==', true)
        .get();

    if (storesSnapshot.empty) {
      console.log('   ⚠️  Không tìm thấy store nào đang mở cửa.');
      return;
    }

    const slotsCollection = db.collection('booking_slots');
    const batch = db.batch();
    let totalSlots = 0;

    // Duyệt qua từng store
    for (const storeDoc of storesSnapshot.docs) {
      const storeId = storeDoc.id;

      // Xóa slots cũ của store này (để tránh duplicate rác)
      const oldSlots = await slotsCollection.where('storeId', '==', storeId).get();
      oldSlots.docs.forEach(doc => batch.delete(doc.ref));

      // Tạo slots cho 7 ngày
      for (let dayOffset = 0; dayOffset < 7; dayOffset++) {
        const date = new Date();
        date.setDate(date.getDate() + dayOffset);
        date.setHours(0, 0, 0, 0);

        // Giả lập giờ mở cửa từ 09:00 - 19:00
        for (let hour = 9; hour < 19; hour++) {
          const startTime = `${hour.toString().padStart(2, '0')}:00`;
          const endTime = `${(hour + 1).toString().padStart(2, '0')}:00`;
          const timeSlot = `${startTime}-${endTime}`;

          const slotId = `slot_${storeId}_${date.toISOString().split('T')[0]}_${startTime}`;
          const slotRef = slotsCollection.doc(slotId);

          batch.set(slotRef, {
            id: slotId,
            storeId: storeId,
            date: admin.firestore.Timestamp.fromDate(date),
            timeSlot: timeSlot,
            duration: 60,
            status: 'available',
            maxCustomers: 3,
            currentBookings: 0,
            priceModifier: (dayOffset >= 5) ? 1.2 : 1.0, // Cuối tuần tăng giá nhẹ
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
          totalSlots++;
        }
      }
    }

    // Commit mỗi 500 operation (Firestore limit), ở đây làm đơn giản commit 1 lần
    // Nếu số lượng store lớn, cần chia batch
    if (totalSlots > 0) {
      await batch.commit();
      console.log(`   ✅ Đã tạo ${totalSlots} slots cho ${storesSnapshot.size} cửa hàng.`);
    }

  } catch (error) {
    console.error('   ❌ Lỗi khi tạo booking slots:', error.message);
  }
}

// ================== HÀM CẬP NHẬT CẤU TRÚC STORE ==================
async function updateStoresStructure(db) {
    console.log('\n🏪 Cập nhật cấu trúc Stores...');
    try {
        const stores = await db.collection('stores').get();
        const batch = db.batch();
        let count = 0;

        stores.docs.forEach(doc => {
            const data = doc.data();
            // Đảm bảo store có field services
            if (!data.services_list) {
                batch.update(doc.ref, {
                    services_list: ['gel_color', 'basic_care_cuticle'], // Default IDs
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
                count++;
            }
        });

        if (count > 0) {
            await batch.commit();
            console.log(`   ✅ Đã cập nhật ${count} stores.`);
        }
    } catch (e) {
        console.error('Lỗi update store:', e);
    }
}

// ================== HÀM CHÍNH ==================
async function setupBookingStructure() {
  console.log('🚀 Bắt đầu cập nhật dữ liệu Firebase...');
  console.log('='.repeat(50));

  const db = initializeFirebase();

  try {
    // 1. Cập nhật Services với cấu trúc mới (quan trọng nhất)
    await createCollection(db, 'services', COLLECTIONS_STRUCTURE.services);

    // 2. Migrate dữ liệu cũ nếu có
    await migrateServiceData(db);

    // 3. Cập nhật các bảng phụ trợ
    await createCollection(db, 'store_working_hours', COLLECTIONS_STRUCTURE.store_working_hours);
    await createCollection(db, 'store_technicians', COLLECTIONS_STRUCTURE.store_technicians);

    // 4. Update store structure
    await updateStoresStructure(db);

    // 5. Sinh slot mới cho toàn bộ hệ thống
    await generateBookingSlots(db);

    console.log('\n' + '='.repeat(50));
    console.log('🎉 NÂNG CẤP DỮ LIỆU THÀNH CÔNG!');
    console.log('='.repeat(50));
    console.log('👉 Bước tiếp theo:');
    console.log('1. Vào Flutter code, sửa model Service để đọc field "storeIds" (List<String>) thay vì "storeId"');
    console.log('2. Sửa query trong BookingService.dart thành: .where("storeIds", arrayContains: storeId)');

  } catch (error) {
    console.error('❌ Script bị lỗi:', error);
    process.exit(1);
  }
}

// ================== CHẠY SCRIPT ==================
if (require.main === module) {
  setupBookingStructure().then(() => {
    console.log('\n✨ Script hoàn thành!');
    process.exit(0);
  }).catch(error => {
    console.error('❌ Script bị lỗi:', error);
    process.exit(1);
  });
}