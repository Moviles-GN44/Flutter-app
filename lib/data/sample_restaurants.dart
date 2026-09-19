import 'package:flutter/material.dart';

import 'package:uniandes_food/models/restaurant.dart';

const sampleRestaurants = <Restaurant>[
  Restaurant(
    id: 'el-corral',
    name: 'El Corral Uniandes',
    category: 'Burgers',
    priceRange: r'$$',
    distanceMeters: 250,
    walkingMinutes: 3,
    rating: 4.2,
    reviewCount: 187,
    waitTime: WaitTime.fiveTo15,
    isOpen: true,
    foodIcon: Icons.lunch_dining_outlined,
    mapPosition: Offset(0.56, 0.43),
    imageAsset: 'assets/images/el_corral.png',
    address: 'Cra 1 #18a-70, Bogotá, near Universidad de los Andes',
    schedule: 'Lun-Dom · 11:00am - 10:00pm',
    phone: '+57 300 555 0198',
    paymentMethods: ['Cash', 'Visa', 'Mastercard', 'Nequi'],
    menu: [
      MenuSection(
        title: 'Burgers',
        items: [
          MenuItem(
            name: 'Corral Todo Terreno',
            description:
                'Double premium beef, melted cheese, bacon and '
                'house sauce.',
            priceCop: 24900,
            waitTime: WaitTime.fiveTo15,
            hasPromo: true,
            dietaryTags: ['Nut-Free'],
          ),
          MenuItem(
            name: 'Corralísima Clásica',
            description:
                '150g of selected beef, lettuce, tomato and '
                'pickles.',
            priceCop: 18500,
            waitTime: WaitTime.fiveTo15,
            dietaryTags: ['Nut-Free'],
          ),
        ],
      ),
      MenuSection(
        title: 'Sides & drinks',
        items: [
          MenuItem(
            name: 'Papas a la francesa',
            description: 'Crispy fries with house seasoning.',
            priceCop: 7900,
            waitTime: WaitTime.under5,
            dietaryTags: ['Vegetarian', 'Nut-Free'],
          ),
          MenuItem(
            name: 'Malteada de vainilla',
            description: 'Hand-spun vanilla milkshake.',
            priceCop: 11500,
            waitTime: WaitTime.under5,
            dietaryTags: ['Vegetarian'],
          ),
        ],
      ),
    ],
    reviews: [
      RestaurantReview(
        author: 'Camila G.',
        comment: 'Excelente hamburguesa, servicio rápido y buen precio.',
        verified: true,
      ),
      RestaurantReview(
        author: 'Julián P.',
        comment: 'Rico, aunque tardó un poco más de lo esperado.',
      ),
    ],
  ),
  Restaurant(
    id: 'verde-bowl',
    name: 'Verde Bowl',
    category: 'Healthy',
    priceRange: r'$$',
    distanceMeters: 180,
    walkingMinutes: 2,
    rating: 4.6,
    reviewCount: 94,
    waitTime: WaitTime.under5,
    isOpen: true,
    foodIcon: Icons.rice_bowl_outlined,
    mapPosition: Offset(0.45, 0.56),
    isVegan: true,
    address: 'Edificio Santo Domingo, Universidad de los Andes',
    schedule: 'Lun-Vie · 10:30am - 6:00pm',
    phone: '+57 301 555 0142',
    paymentMethods: ['Cash', 'Visa', 'Nequi', 'Daviplata'],
    menu: [
      MenuSection(
        title: 'Bowls',
        items: [
          MenuItem(
            name: 'Buddha Bowl',
            description: 'Quinoa, aguacate, garbanzos y vinagreta de limón.',
            priceCop: 21900,
            waitTime: WaitTime.under5,
            dietaryTags: ['Vegan', 'Gluten-Free'],
          ),
          MenuItem(
            name: 'Bowl de pollo teriyaki',
            description: 'Arroz integral, pollo teriyaki y vegetales al wok.',
            priceCop: 23500,
            waitTime: WaitTime.under5,
          ),
        ],
      ),
    ],
    reviews: [
      RestaurantReview(
        author: 'Laura M.',
        comment: 'Porciones generosas y muy fresco. Mi almuerzo fijo.',
        verified: true,
      ),
    ],
  ),
  Restaurant(
    id: 'sushi-nikkei',
    name: 'Sushi Nikkei',
    category: 'Japanese',
    priceRange: r'$$$',
    distanceMeters: 420,
    walkingMinutes: 6,
    rating: 4.4,
    reviewCount: 132,
    waitTime: WaitTime.over15,
    isOpen: true,
    foodIcon: Icons.set_meal_outlined,
    mapPosition: Offset(0.74, 0.50),
    address: 'Cra 4 #18-30, Bogotá',
    schedule: 'Mar-Dom · 12:00pm - 9:30pm',
    phone: '+57 310 555 0177',
    paymentMethods: ['Visa', 'Mastercard', 'Nequi'],
    menu: [
      MenuSection(
        title: 'Rolls',
        items: [
          MenuItem(
            name: 'Nikkei Roll',
            description: 'Salmón, aguacate y salsa acevichada.',
            priceCop: 32900,
            waitTime: WaitTime.over15,
          ),
          MenuItem(
            name: 'Veggie Roll',
            description: 'Pepino, mango y queso crema.',
            priceCop: 26900,
            waitTime: WaitTime.over15,
            dietaryTags: ['Vegetarian'],
          ),
        ],
      ),
    ],
    reviews: [
      RestaurantReview(
        author: 'Andrés R.',
        comment: 'Muy bueno, pero hay que ir con tiempo al mediodía.',
      ),
    ],
  ),
  Restaurant(
    id: 'wok',
    name: 'Wok',
    category: 'Asian',
    priceRange: r'$$',
    distanceMeters: 330,
    walkingMinutes: 5,
    rating: 4.1,
    reviewCount: 76,
    waitTime: WaitTime.fiveTo15,
    isOpen: true,
    foodIcon: Icons.ramen_dining_outlined,
    mapPosition: Offset(0.33, 0.63),
    hasPromo: true,
    address: 'Cra 3 #19-40, Bogotá',
    schedule: 'Lun-Sab · 11:30am - 9:00pm',
    phone: '+57 320 555 0155',
    paymentMethods: ['Cash', 'Visa', 'Mastercard'],
    menu: [
      MenuSection(
        title: 'Wok',
        items: [
          MenuItem(
            name: 'Pad Thai de pollo',
            description: 'Fideos de arroz, maní, tamarindo y cebollín.',
            priceCop: 27900,
            waitTime: WaitTime.fiveTo15,
            hasPromo: true,
          ),
          MenuItem(
            name: 'Arroz thai vegetariano',
            description: 'Arroz jazmín salteado con vegetales y tofu.',
            priceCop: 24900,
            waitTime: WaitTime.fiveTo15,
            dietaryTags: ['Vegetarian'],
          ),
        ],
      ),
    ],
    reviews: [
      RestaurantReview(
        author: 'Sofía T.',
        comment: 'La promo de almuerzo vale mucho la pena.',
        verified: true,
      ),
    ],
  ),
  Restaurant(
    id: 'arepas-seneca',
    name: 'Arepas Séneca',
    category: 'Colombian',
    priceRange: r'$',
    distanceMeters: 290,
    walkingMinutes: 4,
    rating: 4.3,
    reviewCount: 58,
    waitTime: WaitTime.under5,
    isOpen: false,
    foodIcon: Icons.bakery_dining_outlined,
    mapPosition: Offset(0.64, 0.69),
    address: 'Edificio Séneca, Universidad de los Andes',
    schedule: 'Lun-Vie · 7:00am - 4:00pm',
    phone: '+57 315 555 0123',
    paymentMethods: ['Cash', 'Nequi'],
    menu: [
      MenuSection(
        title: 'Arepas',
        items: [
          MenuItem(
            name: 'Arepa de queso',
            description: 'Arepa de maíz blanco con queso costeño.',
            priceCop: 9500,
            waitTime: WaitTime.under5,
            dietaryTags: ['Vegetarian', 'Nut-Free'],
          ),
          MenuItem(
            name: 'Arepa de huevo',
            description: 'Arepa frita rellena de huevo y carne desmechada.',
            priceCop: 11900,
            waitTime: WaitTime.under5,
            dietaryTags: ['Nut-Free'],
          ),
        ],
      ),
    ],
    reviews: [
      RestaurantReview(
        author: 'Mateo V.',
        comment: 'Desayuno rápido y barato entre clases.',
      ),
    ],
  ),
];

Restaurant? fasterAlternativeTo(Restaurant restaurant) {
  final candidates =
      sampleRestaurants
          .where(
            (r) =>
                r.id != restaurant.id &&
                r.isOpen &&
                r.waitTime == WaitTime.under5,
          )
          .toList()
        ..sort((a, b) => a.walkingMinutes.compareTo(b.walkingMinutes));
  return candidates.isEmpty ? null : candidates.first;
}

List<Restaurant> nearbyRestaurants({int limit = 4}) {
  final sorted = [...sampleRestaurants]
    ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  return sorted.take(limit).toList();
}

Restaurant? restaurantByName(String name) {
  for (final restaurant in sampleRestaurants) {
    if (restaurant.name == name) return restaurant;
  }
  return null;
}
