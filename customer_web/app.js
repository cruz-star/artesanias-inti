
// Mock Data (Fallback)
const MOCK_PRODUCTS = [
    {
        id: '1',
        name: 'Vasija de Barro Pintada a Mano',
        description: 'Hermosa vasija de barro cocido con diseños tradicionales andinos pintados completamente a mano.',
        price: 45.00,
        category: 'Cerámica',
        image: 'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?q=80&w=2070&auto=format&fit=crop'
    }
];

// Configuration
const DATA_URL = 'productos.json';

let products = [];
let cart = [];
let currentCategory = 'all';
let storeContact = {
    name: 'Artesanías Inti',
    email: '',
    phone: ''
};

// Selectors
const productGrid = document.getElementById('product-grid');
const cartBtn = document.getElementById('cart-btn');
const cartCount = document.getElementById('cart-count');
const cartDrawer = document.getElementById('cart-drawer');
const closeCart = document.getElementById('close-cart');
const cartItemsContainer = document.getElementById('cart-items');
const cartTotal = document.getElementById('cart-total');
const searchInput = document.getElementById('search-input');
const filterBtns = document.querySelectorAll('.filter-btn');
const checkoutBtn = document.getElementById('checkout-btn');
const confirmOrderBtn = document.getElementById('confirm-order-btn');
const checkoutForm = document.getElementById('checkout-form-container');

// Initialize
document.addEventListener('DOMContentLoaded', async () => {
    await init();
    
    // Event Listeners
    cartBtn.addEventListener('click', () => cartDrawer.classList.add('open'));
    closeCart.addEventListener('click', () => {
        cartDrawer.classList.remove('open');
        resetCheckout();
    });
    
    searchInput.addEventListener('input', (e) => {
        const query = e.target.value.toLowerCase();
        const filtered = products.filter(p => 
            p.name.toLowerCase().includes(query) || 
            p.description.toLowerCase().includes(query)
        );
        renderProducts(filtered);
    });

    filterBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            filterBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            currentCategory = btn.dataset.category;
            const filtered = currentCategory === 'all' 
                ? products 
                : products.filter(p => p.category === currentCategory);
            renderProducts(filtered);
        });
    });

    checkoutBtn.addEventListener('click', () => {
        if (cart.length === 0) {
            alert('Tu carrito está vacío');
            return;
        }
        checkoutForm.style.display = 'block';
        checkoutBtn.style.display = 'none';
        confirmOrderBtn.style.display = 'block';
        cartItemsContainer.style.display = 'none';
    });

    confirmOrderBtn.addEventListener('click', sendOrder);
});

async function init() {
    try {
        const response = await fetch(DATA_URL + '?t=' + Date.now());
        if (response.ok) {
            const data = await response.json();
            products = (data.products && data.products.length > 0) ? data.products : MOCK_PRODUCTS;
            if (data.contact) {
                storeContact = data.contact;
                updateContactsUI();
            }
        } else {
            products = MOCK_PRODUCTS;
        }
    } catch (e) {
        console.warn('Usando datos locales', e);
        products = MOCK_PRODUCTS;
    }
    renderProducts(products);
}

function updateContactsUI() {
    const waText = document.getElementById('contact-phone-text');
    const emailText = document.getElementById('contact-email-text');
    const waLink = document.getElementById('footer-whatsapp');
    const emailLink = document.getElementById('footer-email');

    if (storeContact.phone) {
        waText.innerText = storeContact.phone;
        waLink.href = `https://wa.me/${storeContact.phone.replace(/\D/g, '')}`;
    }
    if (storeContact.email) {
        emailText.innerText = storeContact.email;
        emailLink.href = `mailto:${storeContact.email}`;
    }
}

function renderProducts(productsToRender) {
    productGrid.innerHTML = '';
    productsToRender.forEach(product => {
        const card = document.createElement('div');
        card.className = 'product-card';
        card.innerHTML = `
            <div class="card-img">
                <img src="${product.image || product.imageFileName || 'ic_launcher.png'}" alt="${product.name}">
                <span class="category-badge">${product.category}</span>
            </div>
            <div class="card-info">
                <h4>${product.name}</h4>
                <p>${product.description}</p>
                <div class="card-footer">
                    <span class="price">$ ${product.price.toLocaleString()}</span>
                    <button class="add-btn" onclick="addToCart('${product.id}')">
                        <span class="material-symbols-outlined">add_shopping_cart</span>
                    </button>
                </div>
            </div>
        `;
        productGrid.appendChild(card);
    });
}

window.addToCart = (productId) => {
    const product = products.find(p => p.id === productId);
    const existing = cart.find(item => item.id === productId);

    if (existing) {
        existing.quantity += 1;
    } else {
        cart.push({ ...product, quantity: 1 });
    }

    updateCartUI();
    
    // Feedback
    const btn = event.currentTarget;
    const originalIcon = btn.innerHTML;
    btn.innerHTML = '<span class="material-symbols-outlined">check</span>';
    setTimeout(() => btn.innerHTML = originalIcon, 1000);
};

function updateCartUI() {
    const totalItems = cart.reduce((sum, item) => sum + item.quantity, 0);
    cartCount.innerText = totalItems;
    cartItemsContainer.innerHTML = '';
    let total = 0;

    cart.forEach(item => {
        const itemTotal = item.price * item.quantity;
        total += itemTotal;
        const div = document.createElement('div');
        div.className = 'cart-item';
        div.style.cssText = 'display:flex; gap:1rem; margin-bottom:1rem; align-items:center;';
        div.innerHTML = `
            <img src="${item.image || 'ic_launcher.png'}" style="width:50px; height:50px; border-radius:8px; object-fit:cover;">
            <div style="flex:1">
                <h5 style="margin:0; font-size:0.9rem;">${item.name}</h5>
                <p style="font-size:0.8rem; color:var(--text-dim); margin:0">$ ${item.price.toLocaleString()} x ${item.quantity}</p>
            </div>
            <button onclick="removeFromCart('${item.id}')" style="background:none; border:none; color:var(--primary); cursor:pointer;">
                <span class="material-symbols-outlined" style="font-size:1.2rem;">delete</span>
            </button>
        `;
        cartItemsContainer.appendChild(div);
    });
    cartTotal.innerText = `$ ${total.toLocaleString()}`;
}

window.removeFromCart = (id) => {
    cart = cart.filter(item => item.id !== id);
    updateCartUI();
};

function resetCheckout() {
    checkoutForm.style.display = 'none';
    checkoutBtn.style.display = 'block';
    confirmOrderBtn.style.display = 'none';
    cartItemsContainer.style.display = 'block';
}

function sendOrder() {
    const name = document.getElementById('customer-name').value;
    const address = document.getElementById('customer-address').value;
    const phone = document.getElementById('customer-phone').value;

    if (!name || !address || !phone) {
        alert('Por favor, completa todos los datos para el envío');
        return;
    }

    let message = `*Nuevo Pedido - Artesanías Inti*\n\n`;
    message += `*Cliente:* ${name}\n`;
    message += `*Dirección:* ${address}\n`;
    message += `*Teléfono:* ${phone}\n\n`;
    message += `*Productos:*\n`;
    
    cart.forEach(item => {
        message += `- ${item.name} (x${item.quantity}): $ ${ (item.price * item.quantity).toLocaleString() }\n`;
    });
    
    message += `\n*Total: ${cartTotal.innerText}*`;
    
    const waNumber = storeContact.phone.replace(/\D/g, '');
    const url = `https://wa.me/${waNumber}?text=${encodeURIComponent(message)}`;
    window.open(url, '_blank');
}
