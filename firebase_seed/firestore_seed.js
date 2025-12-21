// complete_booking_structure.js
const admin = require('firebase-admin');
const path = require('path');

// ================== CONFIGURATION ==================
const CONFIG = {
  projectId: 'applamdep-ffa8e',
  serviceAccountPath: path.join(__dirname, 'serviceAccountKey.json'),
};

// ================== INITIALIZE FIREBASE ==================
function initializeFirebase() {
  try {
    const serviceAccount = require(CONFIG.serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: CONFIG.projectId
    });
    console.log(`✅ Đã kết nối Firebase: ${CONFIG.projectId}`);
    return admin.firestore();
  } catch (error) {
    console.error('❌ Lỗi khi initialize Firebase:', error.message);
    process.exit(1);
  }
}

// ================== CẤU TRÚC COLLECTIONS CẦN THIẾT ==================
const COLLECTIONS_STRUCTURE = {
  // 1. BẢNG SERVICES - Dịch vụ của cửa hàng
  services: {
    fields: {
      id: 'string',
      storeId: 'string',
      name: 'string',
      description: 'string',
      price: 'number',
      duration: 'number', // phút
      category: 'string', // 'nail_service', 'additional_service', 'nails_care'
      isActive: 'boolean',
      imageUrl: 'string',
      requiresNailDesign: 'boolean', // có cần chọn mẫu nail không
      position: 'number', // thứ tự hiển thị
      createdAt: 'timestamp',
      updatedAt: 'timestamp'
    },
    sampleData: [
      {
        id: 'basic_manicure',
        storeId: '1',
        name: 'Manicure Cơ Bản',
        description: 'Dưỡng da tay, cắt da, dũa móng',
        price: 80000,
        duration: 30,
        category: 'nails_care',
        isActive: true,
        imageUrl: 'assets/images/services/manicure.png',
        requiresNailDesign: false,
        position: 1
      },
      {
        id: 'gel_color',
        storeId: '1',
        name: 'Sơn Gel Màu',
        description: 'Sơn gel màu cơ bản',
        price: 120000,
        duration: 60,
        category: 'nail_service',
        isActive: true,
        imageUrl: 'assets/images/services/gel_color.png',
        requiresNailDesign: false,
        position: 2
      },
      {
        id: 'nail_art_basic',
        storeId: '1',
        name: 'Vẽ Nail Cơ Bản',
        description: 'Vẽ họa tiết đơn giản',
        price: 50000,
        duration: 20,
        category: 'additional_service',
        isActive: true,
        imageUrl: 'assets/images/services/nail_art.png',
        requiresNailDesign: true,
        position: 3
      },
      {
        id: 'crystal_addon',
        storeId: '1',
        name: 'Đính Đá Pha Lê',
        description: 'Đính đá pha lê lên móng',
        price: 30000,
        duration: 15,
        category: 'additional_service',
        isActive: true,
        imageUrl: 'assets/images/services/crystal.png',
        requiresNailDesign: true,
        position: 4
      }
    ]
  },

  // 2. BẢNG STORE_WORKING_HOURS - Giờ làm việc của cửa hàng
  store_working_hours: {
    fields: {
      id: 'string',
      storeId: 'string',
      dayOfWeek: 'number', // 0 = Chủ nhật, 1 = Thứ 2, ...
      isOpen: 'boolean',
      openTime: 'string', // '09:00'
      closeTime: 'string', // '20:00'
      breakStart: 'string', // '12:00' (tùy chọn)
      breakEnd: 'string', // '13:00' (tùy chọn)
      createdAt: 'timestamp',
      updatedAt: 'timestamp'
    },
    sampleData: [
      {
        id: 'store1_monday',
        storeId: '1',
        dayOfWeek: 1,
        isOpen: true,
        openTime: '08:30',
        closeTime: '20:00',
        breakStart: '12:00',
        breakEnd: '13:00'
      },
      {
        id: 'store1_tuesday',
        storeId: '1',
        dayOfWeek: 2,
        isOpen: true,
        openTime: '08:30',
        closeTime: '20:00'
      },
      {
        id: 'store1_sunday',
        storeId: '1',
        dayOfWeek: 0,
        isOpen: false,
        openTime: '09:00',
        closeTime: '18:00'
      }
    ]
  },

  // 3. BẢNG STORE_TECHNICIANS - Thợ nail của cửa hàng
  store_technicians: {
    fields: {
      id: 'string',
      storeId: 'string',
      name: 'string',
      avatarUrl: 'string',
      specialty: 'array', // ['nail_art', 'gel_nails', 'pedicure']
      experience: 'number', // số năm kinh nghiệm
      rating: 'number',
      isAvailable: 'boolean',
      workingHours: 'array', // các slot làm việc
      createdAt: 'timestamp',
      updatedAt: 'timestamp'
    },
    sampleData: [
      {
        id: 'tech1',
        storeId: '1',
        name: 'Nguyễn Thị Mai',
        avatarUrl: 'https://i.pravatar.cc/150?img=1',
        specialty: ['nail_art', 'gel_nails'],
        experience: 3,
        rating: 4.8,
        isAvailable: true,
        workingHours: ['09:00-12:00', '13:00-18:00']
      },
      {
        id: 'tech2',
        storeId: '1',
        name: 'Trần Văn An',
        avatarUrl: 'https://i.pravatar.cc/150?img=2',
        specialty: ['pedicure', 'manicure'],
        experience: 5,
        rating: 4.9,
        isAvailable: true,
        workingHours: ['10:00-13:00', '14:00-19:00']
      }
    ]
  },

  // 4. BẢNG BOOKING_SLOTS - Slot đặt lịch (sinh tự động)
  booking_slots: {
    fields: {
      id: 'string',
      storeId: 'string',
      technicianId: 'string', // optional
      date: 'timestamp', // ngày
      timeSlot: 'string', // '09:00-10:00'
      duration: 'number', // phút
      status: 'string', // 'available', 'booked', 'blocked'
      maxCustomers: 'number',
      currentBookings: 'number',
      priceModifier: 'number', // hệ số giá (vd: cuối tuần x1.2)
      createdAt: 'timestamp',
      updatedAt: 'timestamp'
    },
    sampleData: [] // sẽ sinh tự động
  },

  // 5. BẢNG APPOINTMENTS (nâng cấp từ booking hiện tại)
  appointments: {
    fields: {
      id: 'string',
      userId: 'string',
      storeId: 'string',
      technicianId: 'string', // optional
      bookingDate: 'timestamp',
      timeSlot: 'string',
      duration: 'number',
      status: 'string', // 'pending', 'confirmed', 'completed', 'cancelled', 'no_show'

      // Nail designs đã chọn
      nailDesigns: 'array', // mảng các mẫu nail
      // Structure của mỗi nail design:
      // {
      //   nailId: 'string',
      //   nailName: 'string',
      //   nailImage: 'string',
      //   price: 'number',
      //   notes: 'string'
      // }

      // Additional services
      additionalServices: 'array',
      // Structure của mỗi service:
      // {
      //   serviceId: 'string',
      //   serviceName: 'string',
      //   price: 'number',
      //   quantity: 'number'
      // }

      totalPrice: 'number',
      discountAmount: 'number',
      finalPrice: 'number',
      couponCode: 'string',

      // Customer info
      customerName: 'string',
      customerPhone: 'string',
      customerNotes: 'string',

      // Payment info
      paymentStatus: 'string', // 'pending', 'paid', 'refunded'
      paymentMethod: 'string', // 'cash', 'card', 'momo'
      paymentId: 'string', // optional

      // Tracking
      createdAt: 'timestamp',
      updatedAt: 'timestamp',
      confirmedAt: 'timestamp',
      completedAt: 'timestamp',
      cancelledAt: 'timestamp',
      cancellationReason: 'string'
    },
    sampleData: []
  },

  // 6. BẢNG STORE_REVIEWS - Đánh giá cửa hàng
  store_reviews: {
    fields: {
      id: 'string',
      storeId: 'string',
      userId: 'string',
      appointmentId: 'string', // liên kết với booking
      rating: 'number', // 1-5
      comment: 'string',
      images: 'array',
      serviceRating: 'number',
      technicianRating: 'number',
      cleanlinessRating: 'number',
      isRecommended: 'boolean',
      helpfulCount: 'number',
      createdAt: 'timestamp',
      updatedAt: 'timestamp'
    },
    sampleData: [
      {
        id: 'review1',
        storeId: '1',
        userId: 'ZohEFTg4pbeWhrmXx6oGqiV902a2',
        appointmentId: '1pKFe8JDPjd0NVR3J7HN',
        rating: 5,
        comment: 'Dịch vụ rất tốt, thợ làm cẩn thận',
        serviceRating: 5,
        technicianRating: 5,
        cleanlinessRating: 4,
        isRecommended: true,
        helpfulCount: 2
      }
    ]
  },

  // 7. BẢNG USER_FAVORITES - Mẫu nail yêu thích
  user_favorites: {
    fields: {
      id: 'string',
      userId: 'string',
      nailId: 'string',
      addedAt: 'timestamp'
    },
    sampleData: [
      {
        userId: 'ZohEFTg4pbeWhrmXx6oGqiV902a2',
        nailId: 'nail1',
        addedAt: admin.firestore.Timestamp.now()
      }
    ]
  },

  // 8. BẢNG NOTIFICATIONS - Thông báo
  notifications: {
    fields: {
      id: 'string',
      userId: 'string',
      title: 'string',
      message: 'string',
      type: 'string', // 'booking', 'promotion', 'reminder', 'system'
      data: 'map', // custom data
      isRead: 'boolean',
      createdAt: 'timestamp'
    },
    sampleData: [
      {
        userId: 'ZohEFTg4pbeWhrmXx6oGqiV902a2',
        title: 'Đặt lịch thành công',
        message: 'Bạn đã đặt lịch làm nail thành công vào 21/12/2025 lúc 14:00',
        type: 'booking',
        data: { appointmentId: '1pKFe8JDPjd0NVR3J7HN' },
        isRead: false
      }
    ]
  }
};

// ================== HÀM TẠO COLLECTION ==================
async function createCollection(db, collectionName, structure) {
  try {
    console.log(`\n📁 Đang tạo collection: ${collectionName}...`);

    // Kiểm tra collection đã tồn tại chưa
    const collections = await db.listCollections();
    const exists = collections.some(col => col.id === collectionName);

    if (exists) {
      console.log(`   ⚠️  Collection ${collectionName} đã tồn tại, bỏ qua...`);
      return;
    }

    // Tạo sample data nếu có
    if (structure.sampleData && structure.sampleData.length > 0) {
      const batch = db.batch();

      structure.sampleData.forEach((data, index) => {
        const docId = data.id || `${collectionName}_${index + 1}`;
        const docRef = db.collection(collectionName).doc(docId);

        // Thêm timestamp nếu chưa có
        const docData = {
          ...data,
          createdAt: data.createdAt || admin.firestore.Timestamp.now(),
          updatedAt: data.updatedAt || admin.firestore.Timestamp.now()
        };

        batch.set(docRef, docData);
      });

      await batch.commit();
      console.log(`   ✅ Đã tạo ${structure.sampleData.length} documents trong ${collectionName}`);
    } else {
      console.log(`   ✅ Đã tạo collection ${collectionName} (không có sample data)`);
    }

  } catch (error) {
    console.error(`   ❌ Lỗi khi tạo ${collectionName}:`, error.message);
  }
}

// ================== HÀM CẬP NHẬT BẢNG HIỆN CÓ ==================
async function updateExistingCollections(db) {
  console.log('\n🔄 Đang cập nhật các bảng hiện có...');

  // 1. Cập nhật bảng users: Thêm field booking_cart_items
  try {
    const usersSnapshot = await db.collection('users').get();
    const batch = db.batch();
    let updateCount = 0;

    usersSnapshot.docs.forEach(doc => {
      const data = doc.data();
      if (!data.booking_cart_items) {
        batch.update(doc.ref, {
          booking_cart_items: [],
          booking_cart_updated: admin.firestore.FieldValue.serverTimestamp()
        });
        updateCount++;
      }
    });

    if (updateCount > 0) {
      await batch.commit();
      console.log(`   ✅ Đã cập nhật ${updateCount} users với booking_cart_items`);
    }
  } catch (error) {
    console.error('   ❌ Lỗi cập nhật users:', error.message);
  }

  // 2. Cập nhật bảng stores: Thêm các field mới
  try {
    const storesRef = db.collection('stores');
    const storesSnapshot = await storesRef.limit(1).get();

    if (!storesSnapshot.empty) {
      const storeDoc = storesSnapshot.docs[0];
      const updateData = {
        average_rating: 4.5,
        total_reviews: 0,
        services_count: 0,
        technicians_count: 0,
        is_booking_enabled: true,
        booking_notice: 'Vui lòng đặt lịch trước ít nhất 2 giờ',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      await storeDoc.ref.update(updateData);
      console.log('   ✅ Đã cập nhật stores với các field mới');
    }
  } catch (error) {
    console.error('   ❌ Lỗi cập nhật stores:', error.message);
  }

  // 3. Cập nhật bảng coupons: Thêm các field mới
  try {
    const couponsSnapshot = await db.collection('coupons').get();
    const batch = db.batch();

    couponsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const updates = {};

      if (!data.applicableServiceCategories) {
        updates.applicableServiceCategories = ['all'];
      }
      if (!data.maxDiscountAmount) {
        updates.maxDiscountAmount = 500000;
      }
      if (!data.isFirstBookingOnly) {
        updates.isFirstBookingOnly = false;
      }
      if (!data.customerSegment) {
        updates.customerSegment = 'all';
      }

      if (Object.keys(updates).length > 0) {
        batch.update(doc.ref, updates);
      }
    });

    await batch.commit();
    console.log('   ✅ Đã cập nhật coupons với các field mới');
  } catch (error) {
    console.error('   ❒ Lỗi cập nhật coupons:', error.message);
  }

  // 4. Tạo booking slots cho 7 ngày tới
  try {
    console.log('\n⏰ Đang tạo booking slots cho 7 ngày tới...');
    await generateBookingSlots(db);
  } catch (error) {
    console.error('   ❌ Lỗi tạo booking slots:', error.message);
  }
}

// ================== HÀM SINH BOOKING SLOTS ==================
async function generateBookingSlots(db) {
  try {
    const stores = await db.collection('stores').limit(1).get();
    if (stores.empty) {
      console.log('   ⚠️  Không tìm thấy store nào, bỏ qua tạo slots');
      return;
    }

    const storeId = stores.docs[0].id;
    const slotsCollection = db.collection('booking_slots');

    // Xóa slots cũ (nếu có)
    const oldSlots = await slotsCollection.where('storeId', '==', storeId).get();
    if (!oldSlots.empty) {
      const deleteBatch = db.batch();
      oldSlots.docs.forEach(doc => deleteBatch.delete(doc.ref));
      await deleteBatch.commit();
    }

    // Tạo slots cho 7 ngày tới
    const batch = db.batch();
    let slotCount = 0;

    for (let dayOffset = 0; dayOffset < 7; dayOffset++) {
      const date = new Date();
      date.setDate(date.getDate() + dayOffset);
      date.setHours(0, 0, 0, 0);

      // Tạo các time slot từ 9:00 đến 19:00, mỗi slot 60 phút
      for (let hour = 9; hour < 19; hour++) {
        const startTime = `${hour.toString().padStart(2, '0')}:00`;
        const endTime = `${(hour + 1).toString().padStart(2, '0')}:00`;
        const timeSlot = `${startTime}-${endTime}`;

        const slotId = `slot_${storeId}_${date.toISOString().split('T')[0]}_${startTime}`;
        const slotRef = slotsCollection.doc(slotId);

        const slotData = {
          id: slotId,
          storeId: storeId,
          date: admin.firestore.Timestamp.fromDate(date),
          timeSlot: timeSlot,
          duration: 60,
          status: 'available',
          maxCustomers: 3,
          currentBookings: 0,
          priceModifier: (dayOffset >= 5) ? 1.2 : 1.0, // Cuối tuần đắt hơn
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        batch.set(slotRef, slotData);
        slotCount++;
      }
    }

    await batch.commit();
    console.log(`   ✅ Đã tạo ${slotCount} booking slots cho store ${storeId}`);

  } catch (error) {
    console.error('   ❌ Lỗi khi tạo booking slots:', error.message);
  }
}

// ================== HÀM TẠO BOOKING SAMPLE ==================
async function createSampleBooking(db) {
  console.log('\n📅 Đang tạo sample booking...');

  try {
    const bookingId = 'sample_booking_1';
    const bookingRef = db.collection('bookings').doc(bookingId);

    const bookingData = {
      id: bookingId,
      userId: 'ZohEFTg4pbeWhrmXx6oGqiV902a2',
      storeId: '1',
      bookingDate: admin.firestore.Timestamp.fromDate(new Date('2025-12-22T14:00:00')),
      timeSlot: '14:00-15:00',
      duration: 90,
      status: 'confirmed',

      // Nail designs
      nailDesigns: [
        {
          nailId: 'nail1',
          nailName: 'Milky White Pearl',
          nailImage: 'assets/images/nail1.png',
          price: 180000,
          notes: 'Vui lòng làm móng dài'
        }
      ],

      // Additional services
      additionalServices: [
        {
          serviceId: 'nail_art_basic',
          serviceName: 'Vẽ Nail Cơ Bản',
          price: 50000,
          quantity: 1
        },
        {
          serviceId: 'crystal_addon',
          serviceName: 'Đính Đá Pha Lê',
          price: 30000,
          quantity: 2
        }
      ],

      totalPrice: 260000,
      discountAmount: 0,
      finalPrice: 260000,

      // Customer info
      customerName: 'TRANG NGUYEN',
      customerPhone: '034465644444444',
      customerNotes: 'K',

      // Payment info
      paymentStatus: 'paid',
      paymentMethod: 'cash',

      // Tracking
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      confirmedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await bookingRef.set(bookingData);
    console.log('   ✅ Đã tạo sample booking');

  } catch (error) {
    console.error('   ❌ Lỗi tạo sample booking:', error.message);
  }
}

// ================== HÀM CHÍNH ==================
async function setupBookingStructure() {
  console.log('🚀 Bắt đầu thiết lập cấu trúc Booking...');
  console.log('='.repeat(50));

  const db = initializeFirebase();

  try {
    // 1. Tạo các collections mới
    const collections = Object.keys(COLLECTIONS_STRUCTURE);

    for (const collectionName of collections) {
      await createCollection(db, collectionName, COLLECTIONS_STRUCTURE[collectionName]);
    }

    // 2. Cập nhật các collections hiện có
    await updateExistingCollections(db);

    // 3. Tạo sample booking
    await createSampleBooking(db);

    // 4. Tạo index cho query hiệu quả
    await createIndexes(db);

    console.log('\n' + '='.repeat(50));
    console.log('🎉 HOÀN TẤT THIẾT LẬP CẤU TRÚC BOOKING!');
    console.log('='.repeat(50));
    console.log('\n📊 CÁC BẢNG ĐÃ ĐƯỢC TẠO/CẬP NHẬT:');
    console.log('1. ✅ services - Dịch vụ của cửa hàng');
    console.log('2. ✅ store_working_hours - Giờ làm việc');
    console.log('3. ✅ store_technicians - Thợ nail');
    console.log('4. ✅ booking_slots - Slot đặt lịch');
    console.log('5. ✅ appointments - Cuộc hẹn (nâng cấp từ bookings)');
    console.log('6. ✅ store_reviews - Đánh giá');
    console.log('7. ✅ user_favorites - Yêu thích');
    console.log('8. ✅ notifications - Thông báo');
    console.log('\n9. ✅ users - Đã cập nhật booking_cart_items');
    console.log('10. ✅ stores - Đã thêm thông tin booking');
    console.log('11. ✅ coupons - Đã thêm tính năng mới');
    console.log('\n📝 GHI CHÚ QUAN TRỌNG:');
    console.log('- Bảng "bookings" cũ sẽ được dùng song song với "appointments" mới');
    console.log('- Có thể migrate dữ liệu cũ sang appointments sau');
    console.log('- Booking slots được tạo tự động cho 7 ngày tới');
    console.log('\n🔗 Firebase Console: https://console.firebase.google.com/project/' + CONFIG.projectId + '/firestore');

  } catch (error) {
    console.error('❌ Lỗi khi thiết lập cấu trúc:', error);
    process.exit(1);
  }
}

// ================== HÀM TẠO INDEX ==================
async function createIndexes(db) {
  console.log('\n🔍 Đang tạo indexes cho query...');

  const indexes = [
    { collection: 'booking_slots', fields: ['storeId', 'date', 'status'] },
    { collection: 'appointments', fields: ['userId', 'status', 'bookingDate'] },
    { collection: 'services', fields: ['storeId', 'category', 'isActive'] },
    { collection: 'store_reviews', fields: ['storeId', 'createdAt'] },
    { collection: 'user_favorites', fields: ['userId', 'addedAt'] }
  ];

  console.log('   ℹ️  Indexes sẽ được tạo tự động khi query lần đầu');
  console.log('   📋 Vào Firebase Console → Firestore → Indexes để quản lý');
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

module.exports = { setupBookingStructure };