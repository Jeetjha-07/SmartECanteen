import '../models/food_item.dart';

class MenuData {
  static List<FoodItem> get menuItems => [
        FoodItem(
          id: '1',
          name: 'Chicken Biryani',
          description: 'Aromatic basmati rice with tender chicken and spices',
          price: 250.0,
          imageUrl:
              'https://tse1.mm.bing.net/th/id/OIP.CMV98hR5u-F4o_B_yPT7zgHaE8?pid=Api&P=0&h=220',
          category: 'Main Course',
          restaurantId: 'default-restaurant',
        ),
        FoodItem(
          id: '2',
          name: 'Margherita Pizza',
          description: 'Fresh tomatoes, mozzarella, and basil on crispy crust',
          price: 320.0,
          imageUrl:
              'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
          category: 'Pizza',
          restaurantId: 'default-restaurant',
        ),
        FoodItem(
          id: '3',
          name: 'Veggie Burger',
          description: 'Grilled veggie patty with lettuce, tomato, and cheese',
          price: 180.0,
          imageUrl:
              'https://images.unsplash.com/photo-1571091718767-18b5b1457add?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
          category: 'Burgers',
          restaurantId: 'default-restaurant',
        ),
        FoodItem(
          id: '4',
          name: 'Masala Chai',
          description: 'Traditional Indian spiced tea with milk',
          price: 25.0,
          imageUrl:
              'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
          category: 'Beverages',
          restaurantId: 'default-restaurant',
        ),
        FoodItem(
          id: '5',
          name: 'Pasta Alfredo',
          description: 'Creamy alfredo sauce with fettuccine pasta',
          price: 280.0,
          imageUrl:
              'https://images.unsplash.com/photo-1555949258-eb67b1ef0ceb?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
          category: 'Pasta',
          restaurantId: 'default-restaurant',
        ),
        FoodItem(
          id: '6',
          name: 'Chocolate Brownie',
          description: 'Rich chocolate brownie with vanilla ice cream',
          price: 120.0,
          imageUrl:
              'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
          category: 'Desserts',
          restaurantId: 'default-restaurant',
        ),
        FoodItem(
          id: '7',
          name: 'Paneer Tikka',
          description: 'Grilled cottage cheese with aromatic spices',
          price: 200.0,
          imageUrl:
              'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
          category: 'Appetizers',
          restaurantId: 'default-restaurant',
        ),
        FoodItem(
          id: '8',
          name: 'Mango Lassi',
          description: 'Refreshing yogurt drink with fresh mango',
          price: 60.0,
          imageUrl:
              'https://images.unsplash.com/photo-1546833999-b9f581a1996d?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
          category: 'Beverages',
          restaurantId: 'default-restaurant',
        ),
      ];
}
