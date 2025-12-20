const admin = require('firebase-admin');
const path = require('path');

// ================== CONFIGURATION ==================
const CONFIG = {
  projectId: 'applamdep-ffa8e',

  // Hoặc dùng service account file
  serviceAccountPath: path.join(__dirname, 'serviceAccountKey.json'),

  // Các collections sẽ được tạo
  collections: [
    'nail_chatbot_users',
    'nail_chatbot_chats',
    'nail_chatbot_messages',
    'nail_designs',
    'appointments'
  ],

  // Số lượng sample data mỗi collection
  sampleCounts: {
    users: 3,
    chats: 5,
    messages: 20,
    designs: 10,
    appointments: 3
  }
};

// ================== INITIALIZE FIREBASE ==================
function initializeFirebase() {
  try {
    // Cách 1: Dùng service account file
    const serviceAccount = require(CONFIG.serviceAccountPath);

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: CONFIG.projectId
    });

    console.log(`✅ Đã kết nối Firebase: ${CONFIG.projectId}`);
    return admin.firestore();

  } catch (error) {
    console.error('❌ Lỗi khi initialize Firebase:', error.message);

    // Cách 2: Nếu không có service account, dùng environment
    try {
      admin.initializeApp({
        projectId: CONFIG.projectId
      });

      console.log(`✅ Đã kết nối với project: ${CONFIG.projectId}`);
      return admin.firestore();

    } catch (fallbackError) {
      console.error('❌ Cần cấu hình Firebase:', fallbackError.message);
      console.log('\n📋 HƯỚNG DẪN CẤU HÌNH:');
      console.log('1. Vào Firebase Console → Project Settings');
      console.log('2. Chọn tab "Service accounts"');
      console.log('3. Click "Generate new private key"');
      console.log('4. Tải file JSON và đặt tên là "serviceAccountKey.json"');
      console.log('5. Đặt file trong cùng thư mục với script này');
      process.exit(1);
    }
  }
}

// ================== SAMPLE DATA GENERATORS ==================
function generateUserData(userId, index) {
  const names = ['Nguyễn Thị Mai', 'Trần Văn An', 'Lê Thị Hương', 'Phạm Văn Minh', 'Hoàng Thị Lan'];
  const emails = ['mai.nguyen@email.com', 'an.tran@email.com', 'huong.le@email.com', 'minh.pham@email.com', 'lan.hoang@email.com'];
  const phones = ['+84987654321', '+84981234567', '+84986543210', '+84987776655', '+84989998877'];

  return {
    userId: userId,
    userType: 'customer',
    name: names[index % names.length],
    email: emails[index % emails.length],
    phone: phones[index % phones.length],
    avatarUrl: `https://i.pravatar.cc/150?img=${index + 1}`,

    registration: {
      method: index === 0 ? 'email' : (index === 1 ? 'google' : 'anonymous'),
      createdAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - (index * 86400000))), // Mỗi user cách nhau 1 ngày
      lastLogin: admin.firestore.Timestamp.now(),
      deviceInfo: {
        platform: index % 2 === 0 ? 'iOS' : 'Android',
        version: '1.2.' + index,
        model: index % 2 === 0 ? 'iPhone 14 Pro' : 'Samsung Galaxy S23'
      }
    },

    status: {
      isActive: true,
      isPremium: index < 2, // 2 user đầu là premium
      isBanned: false,
      lastSeen: admin.firestore.Timestamp.now()
    },

    metadata: {
      totalChats: Math.floor(Math.random() * 10) + 1,
      totalMessages: Math.floor(Math.random() * 100) + 10,
      savedDesigns: Math.floor(Math.random() * 20) + 1,
      appointments: Math.floor(Math.random() * 5),
      analysisCount: Math.floor(Math.random() * 10)
    }
  };
}

function generateChatData(chatId, userId, index) {
  const categories = ['color_analysis', 'design_suggestion', 'product_recommendation', 'booking', 'general'];
  const titles = [
    'Tư vấn màu nail phù hợp',
    'Gợi ý mẫu nail công sở',
    'Đặt lịch làm nail cuối tuần',
    'Hỏi về sản phẩm chăm sóc móng',
    'Trend nail mùa hè 2024'
  ];

  const now = new Date();
  const chatDate = new Date(now.getTime() - (index * 3600000)); // Mỗi chat cách nhau 1 giờ

  return {
    chatId: chatId,
    userId: userId,

    chatInfo: {
      title: titles[index % titles.length],
      description: `Cuộc trò chuyện về ${categories[index % categories.length]}`,
      category: categories[index % categories.length],
      status: 'active',
      createdAt: admin.firestore.Timestamp.fromDate(chatDate),
      updatedAt: admin.firestore.Timestamp.fromDate(chatDate),
      duration: Math.floor(Math.random() * 300) + 60 // 1-5 phút
    },

    aiConfig: {
      personality: index % 3 === 0 ? 'friendly' : (index % 3 === 1 ? 'professional' : 'creative'),
      model: 'gpt-4',
      temperature: 0.7,
      maxTokens: 1000
    },

    participants: {
      user: {
        userId: userId,
        name: `User ${index + 1}`,
        role: 'customer'
      },
      ai: {
        id: 'nail_assistant_ai',
        name: 'Nail Assistant AI',
        role: 'assistant',
        version: '1.2.3'
      }
    },

    statistics: {
      totalMessages: Math.floor(Math.random() * 20) + 5,
      userMessages: Math.floor(Math.random() * 10) + 2,
      aiMessages: Math.floor(Math.random() * 10) + 3,
      hasImages: index % 3 === 0,
      hasVoice: index % 4 === 0,
      hasAnalysis: index % 2 === 0,
      wordCount: Math.floor(Math.random() * 500) + 100
    },

    analysisSummary: {
      skinTone: ['fair', 'light', 'warm_medium', 'olive'][index % 4],
      recommendedColors: ['#FFCDD2', '#F8BBD0', '#E1BEE7'].slice(0, (index % 3) + 1),
      nailLength: ['short', 'medium', 'long'][index % 3],
      suggestedStyles: ['french', 'minimalist', 'glam', 'natural'].slice(0, (index % 4) + 1),
      mood: ['professional', 'casual', 'party', 'romantic'][index % 4],
      confidenceScore: 0.7 + (Math.random() * 0.3)
    },

    tags: ['consultation', 'nail_care', 'beauty'].concat(categories[index % categories.length]),

    metadata: {
      device: index % 2 === 0 ? 'iPhone' : 'Android',
      appVersion: '1.2.' + index,
      location: ['Hà Nội', 'TP.HCM', 'Đà Nẵng'][index % 3],
      timezone: '+7'
    },

    isArchived: index === 4, // Chat cuối archived
    isStarred: index < 2, // 2 chat đầu starred
    isDeleted: false,
    deletedAt: null
  };
}

function generateMessageData(messageId, chatId, userId, sequence) {
  const isAI = sequence % 3 === 0; // Mỗi 3 message có 1 AI message
  const senderType = isAI ? 'ai' : 'user';
  const senderName = isAI ? 'Nail Assistant AI' : `User ${userId}`;

  const messageTypes = isAI ?
    ['text', 'analysis', 'product', 'booking'] :
    ['text', 'image', 'voice', 'quick_reply'];

  const messageType = messageTypes[sequence % messageTypes.length];

  // Nội dung theo type
  const contents = {
    text: {
      user: [
        "Chào bạn, tôi cần tư vấn về màu nail",
        "Màu nào hợp với da tôi nhỉ?",
        "Tôi muốn làm nail đi tiệc",
        "Bạn có gợi ý mẫu nail nào không?",
        "Giá làm nail French tip là bao nhiêu?"
      ],
      ai: [
        "Chào bạn! Tôi có thể giúp gì cho bạn?",
        "Da bạn thuộc tông ấm, nên chọn màu pastel",
        "Tôi đề xuất mẫu French tip thanh lịch",
        "Giá dịch vụ khoảng 250.000 - 350.000 VNĐ",
        "Bạn có muốn xem một số mẫu nail không?"
      ]
    }
  };

  const contentIndex = sequence % 5;
  const textContent = isAI ?
    contents.text.ai[contentIndex] :
    contents.text.user[contentIndex];

  return {
    messageId: messageId,
    chatId: chatId,
    userId: userId,

    sender: {
      type: senderType,
      id: isAI ? 'nail_assistant_ai' : userId,
      name: senderName,
      role: isAI ? 'assistant' : 'customer'
    },

    content: {
      text: textContent,
      type: messageType,
      language: 'vi',
      sentiment: 'neutral',
      tone: isAI ? 'helpful' : 'question'
    },

    timestamp: {
      sentAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - (sequence * 60000))), // Mỗi message cách 1 phút
      receivedAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - (sequence * 60000) + 1000)),
      readAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - (sequence * 60000) + 5000))
    },

    metadata: {
      sequence: sequence,
      isEdited: false,
      editedAt: null,
      reactions: [],
      forwarded: false
    },

    // Thêm data theo type
    ...(messageType === 'analysis' && isAI ? {
      messageTypeData: {
        analysis: {
          analysisType: 'skin_tone',
          method: 'ai_analysis',
          data: {
            skinTone: 'warm_medium',
            recommendations: [
              {
                color: '#FFCDD2',
                reason: 'Hợp với da ấm',
                confidence: 0.92
              }
            ]
          }
        }
      }
    } : {}),

    ...(isAI ? {
      aiResponse: {
        model: 'gpt-4',
        temperature: 0.7,
        tokens: textContent.length,
        processingTime: 1.2 + (Math.random() * 0.5),
        confidence: 0.8 + (Math.random() * 0.2)
      }
    } : {})
  };
}

function generateDesignData(designId, index) {
  const designs = [
    {
      name: 'French Tip Minimalist',
      category: 'french',
      style: 'minimalist',
      difficulty: 'easy'
    },
    {
      name: 'Gradient Glitter Ombre',
      category: 'gradient',
      style: 'glam',
      difficulty: 'medium'
    },
    {
      name: 'Natural Nude Matte',
      category: 'matte',
      style: 'natural',
      difficulty: 'easy'
    },
    {
      name: 'Marble Effect Swirl',
      category: 'art',
      style: 'artistic',
      difficulty: 'hard'
    },
    {
      name: 'Sparkling Crystal',
      category: 'crystal',
      style: 'luxury',
      difficulty: 'hard'
    }
  ];

  const design = designs[index % designs.length];

  return {
    designId: designId,
    name: design.name,
    category: design.category,
    style: design.style,
    difficulty: design.difficulty,
    duration: [60, 90, 120, 150, 180][index % 5],
    priceRange: ['200K-300K', '300K-400K', '400K-500K', '500K-600K', '600K-800K'][index % 5],

    images: [
      {
        url: `https://images.unsplash.com/photo-${1604654894610 + index}`,
        thumbnail: `https://images.unsplash.com/photo-${1604654894610 + index}?w=400`,
        colorPalette: ['#FFCDD2', '#F8BBD0', '#E1BEE7'].slice(0, (index % 3) + 1)
      }
    ],

    description: `Mẫu nail ${design.name} ${design.style} phù hợp cho nhiều dịp`,
    tags: [design.category, design.style, 'nail', 'beauty', 'design'],

    recommendations: {
      skinTones: ['fair', 'light', 'warm_medium', 'olive'],
      nailLengths: ['short', 'medium', 'long'],
      occasions: ['work', 'party', 'wedding', 'daily'],
      seasons: ['spring', 'summer', 'fall', 'winter']
    },

    savedCount: Math.floor(Math.random() * 100),
    viewCount: Math.floor(Math.random() * 500),
    rating: 4 + (Math.random() * 1),
    createdAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - (index * 86400000))),
    updatedAt: admin.firestore.Timestamp.now()
  };
}

// ================== MAIN SEED FUNCTION ==================
async function seedFirestore() {
  const db = initializeFirebase();

  try {
    console.log('🚀 Bắt đầu seed data cho Nail Chatbot...');
    console.log(`📁 Project: ${CONFIG.projectId}`);
    console.log('=' .repeat(50));

    // ================== SEED USERS ==================
    console.log('\n👥 Đang seed users...');
    const users = [];

    for (let i = 0; i < CONFIG.sampleCounts.users; i++) {
      const userId = `user_demo_${i + 1}`;
      const userData = generateUserData(userId, i);

      await db.collection('nail_chatbot_users').doc(userId).set(userData);
      users.push({ id: userId, data: userData });

      // Tạo user preferences
      await db.collection('nail_chatbot_users').doc(userId)
        .collection('user_preferences').doc('preferences').set({
          aiSettings: {
            personality: 'friendly',
            detailLevel: 'detailed',
            autoSuggest: true,
            voiceEnabled: false,
            notifications: true,
            autoSaveChat: true,
            language: 'vi'
          },
          nailProfile: {
            skinTone: userData.analysisSummary?.skinTone || 'warm_medium',
            nailLength: userData.analysisSummary?.nailLength || 'medium',
            nailShape: 'oval',
            nailHealth: 'good'
          },
          createdAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now()
        });
    }
    console.log(`✅ Đã tạo ${users.length} users`);

    // ================== SEED CHATS ==================
    console.log('\n💬 Đang seed chats...');
    const chats = [];

    for (let i = 0; i < CONFIG.sampleCounts.chats; i++) {
      const user = users[i % users.length];
      const chatId = `chat_demo_${i + 1}`;
      const chatData = generateChatData(chatId, user.id, i);

      await db.collection('nail_chatbot_chats').doc(chatId).set(chatData);
      chats.push({ id: chatId, userId: user.id, data: chatData });
    }
    console.log(`✅ Đã tạo ${chats.length} chats`);

    // ================== SEED MESSAGES ==================
    console.log('\n✉️  Đang seed messages...');
    let messageCount = 0;

    for (const chat of chats) {
      const messagesPerChat = Math.floor(CONFIG.sampleCounts.messages / chats.length);

      for (let j = 0; j < messagesPerChat; j++) {
        const messageId = `msg_${chat.id}_${j + 1}`;
        const messageData = generateMessageData(
          messageId,
          chat.id,
          chat.userId,
          j
        );

        await db.collection('nail_chatbot_messages').doc(messageId).set(messageData);
        messageCount++;
      }
    }
    console.log(`✅ Đã tạo ${messageCount} messages`);

    // ================== SEED DESIGNS ==================
    console.log('\n🎨 Đang seed nail designs...');

    for (let i = 0; i < CONFIG.sampleCounts.designs; i++) {
      const designId = `design_${i + 1}`;
      const designData = generateDesignData(designId, i);

      await db.collection('nail_designs').doc(designId).set(designData);
    }
    console.log(`✅ Đã tạo ${CONFIG.sampleCounts.designs} nail designs`);

    // ================== SUMMARY ==================
    console.log('\n' + '=' .repeat(50));
    console.log('🎉 SEED DATA HOÀN TẤT!');
    console.log('=' .repeat(50));
    console.log(`👥 Users: ${users.length}`);
    console.log(`💬 Chats: ${chats.length}`);
    console.log(`✉️  Messages: ${messageCount}`);
    console.log(`🎨 Designs: ${CONFIG.sampleCounts.designs}`);
    console.log('\n📊 Cấu trúc database đã được tạo:');
    console.log('- nail_chatbot_users');
    console.log('- nail_chatbot_chats');
    console.log('- nail_chatbot_messages');
    console.log('- nail_designs');
    console.log('\n🔗 Firebase Console: https://console.firebase.google.com/project/' + CONFIG.projectId + '/firestore');

  } catch (error) {
    console.error('❌ Lỗi khi seed data:', error);
    process.exit(1);
  }
}

// ================== RUN SCRIPT ==================
if (require.main === module) {
  seedFirestore().then(() => {
    console.log('\n✨ Seed script hoàn thành!');
    process.exit(0);
  });
}

module.exports = { seedFirestore };