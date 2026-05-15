// v1.0.1 Mercado Libre Style App Logic
const API_BASE = '/api';
const API_URL = API_BASE; // Define API_URL for consistency
const PRODUCTS_URL = `${API_BASE}/products/`;
const AUTH_URL = `${API_BASE}/auth`;
const CONFIG_URL = `${API_BASE}/config/`;
const PAYMENTS_URL = `${API_BASE}/payments/create-preference`;

let products = [];
let cart = JSON.parse(localStorage.getItem('cart') || '[]');
let currentUser = JSON.parse(localStorage.getItem('user') || 'null');
let token = localStorage.getItem('token');
let currentView = 'home';
let selectedProduct = null;

// Selectors
const views = {
    home: document.getElementById('home-view'),
    auth: document.getElementById('auth-view'),
    detail: document.getElementById('product-detail-view'),
    cart: document.getElementById('cart-view')
};

const productGrid = document.getElementById('product-grid');
const cartCountLabel = document.getElementById('cart-count');
const userNameLabel = document.getElementById('user-name-label');

// Initialize
document.addEventListener('DOMContentLoaded', async () => {
    initCarousel();
    await loadProducts();
    await loadConfig();
    updateUI();
    
    // Routing
    window.addEventListener('popstate', handleRouting);
    document.getElementById('logo-link').addEventListener('click', (e) => {
        e.preventDefault();
        navigateTo('home');
    });
    document.getElementById('user-profile-btn').addEventListener('click', (e) => {
        e.preventDefault();
        if (currentUser) navigateTo('profile');
        else navigateTo('auth');
    });
    document.getElementById('cart-btn').addEventListener('click', (e) => {
        e.preventDefault();
        navigateTo('cart');
    });
});

async function loadProducts() {
    try {
        const res = await fetch(PRODUCTS_URL);
        products = await res.json();
        renderProducts(products);
    } catch (e) {
        console.error('Error loading products', e);
    }
}

async function loadConfig() {
    try {
        const res = await fetch(CONFIG_URL);
        const config = await res.json();
        // Handle config if needed
    } catch (e) {}
}

function renderProducts(items) {
    if (!productGrid) return;
    productGrid.innerHTML = '';
    items.forEach(product => {
        const card = document.createElement('div');
        card.className = 'product-card';
        const mediaUrl = resolveMediaUrl(product);
        
        card.innerHTML = `
            <div class="card-img" onclick="viewProduct('${product.id}')">
                <img src="${mediaUrl}" alt="${product.name}">
            </div>
            <div class="card-content" onclick="viewProduct('${product.id}')">
                <div class="card-price">${formatCurrency(product.price)}</div>
                <div class="card-title">${product.name}</div>
                <div class="shipping-free">Envío gratis</div>
            </div>
        `;
        productGrid.appendChild(card);
    });
}

function resolveMediaUrl(product) {
    if (product.mediaUrls && product.mediaUrls.length > 0) {
        const url = product.mediaUrls[0];
        if (url.startsWith('http')) return url;
        return `/public/media/${url.split('/').pop()}`;
    }
    return 'ic_launcher.png';
}

function formatCurrency(val) {
    const formatted = new Intl.NumberFormat('es-AR', {
        minimumFractionDigits: 0
    }).format(val);
    return `$ ${formatted}`;
}

// Navigation
function navigateTo(view, id = null) {
    currentView = view;
    Object.keys(views).forEach(v => {
        if (views[v]) views[v].classList.remove('active');
    });
    
    const adminView = document.getElementById('admin-view');
    if (adminView) adminView.classList.remove('active');

    if (view === 'home') {
        window.scrollTo(0, 0);
    } else if (view === 'admin') {
        if (adminView) adminView.classList.add('active');
        renderAdminView();
    } else {
        if (views[view]) views[view].classList.add('active');
    }

    if (view === 'detail' && id) {
        renderProductDetail(id);
    } else if (view === 'cart') {
        renderCart();
    } else if (view === 'orders') {
        renderOrders();
    }

    history.pushState({view, id}, '', `#${view}${id ? '/' + id : ''}`);
}

function handleRouting() {
    const hash = window.location.hash.replace('#', '');
    const [view, id] = hash.split('/');
    if (view) navigateTo(view, id);
    else navigateTo('home');
}

// Product Detail
function viewProduct(id) {
    navigateTo('detail', id);
}

function renderProductDetail(id) {
    const product = products.find(p => p.id === id);
    if (!product) return;
    
    const container = views.detail;
    const mediaUrl = resolveMediaUrl(product);
    
    container.innerHTML = `
        <div class="section-card" style="display:flex; gap:32px; flex-wrap:wrap;">
            <div style="flex:1; min-width:300px;">
                <img src="${mediaUrl}" style="width:100%; border-radius:4px; border:1px solid #eee;">
            </div>
            <div style="flex:1; min-width:300px;">
                <p style="color:var(--text-dim); font-size:0.9rem; margin-bottom:8px;">Nuevo | +100 vendidos</p>
                <h1 style="font-size:1.6rem; margin-bottom:16px;">${product.name}</h1>
                <div style="font-size:2.2rem; margin-bottom:24px;">${formatCurrency(product.price)}</div>
                
                <div style="background:#f5f5f5; padding:16px; border-radius:8px; margin-bottom:24px;">
                    <p style="color:var(--success); font-weight:600;"><span class="material-symbols-outlined" style="vertical-align:middle">local_shipping</span> Envío gratis a todo el país</p>
                    <p style="color:var(--text-dim); font-size:0.8rem; margin-left:28px;">Conoce los tiempos y formas de envío.</p>
                </div>

                <button class="primary-btn" onclick="buyNow('${product.id}')" style="margin-bottom:8px; font-size:1.1rem; padding:16px;">Comprar ahora</button>
                <button class="secondary-btn" onclick="addToCart('${product.id}')" style="font-size:1.1rem; padding:16px;">Agregar al carrito</button>
                
                <div style="margin-top:32px;">
                    <h4 style="margin-bottom:12px;">Descripción</h4>
                    <p style="color:var(--text-dim); line-height:1.6;">${product.description}</p>
                </div>
            </div>
        </div>
    `;
}

// Cart Logic
function addToCart(id) {
    const product = products.find(p => p.id === id);
    const existing = cart.find(item => item.id === id);
    if (existing) existing.quantity++;
    else cart.push({...product, quantity: 1});
    
    saveCart();
    updateUI();
    alert('Producto agregado al carrito');
}

function buyNow(id) {
    const product = products.find(p => p.id === id);
    const existing = cart.find(item => item.id === id);
    if (!existing) cart.push({...product, quantity: 1});
    saveCart();
    navigateTo('cart');
}

function saveCart() {
    localStorage.setItem('cart', JSON.stringify(cart));
}

function renderCart() {
    const listContainer = document.getElementById('cart-items-list');
    const summaryContainer = document.getElementById('cart-summary-content');
    
    if (!listContainer || !summaryContainer) return;

    if (cart.length === 0) {
        listContainer.innerHTML = `
            <div style="text-align:center; padding:32px;">
                <span class="material-symbols-outlined" style="font-size:3rem; color:#eee;">shopping_cart</span>
                <p style="margin-top:12px; color:var(--text-dim);">Tu carrito está vacío</p>
            </div>
        `;
        summaryContainer.innerHTML = '<p style="text-align:center; color:var(--text-dim);">Agrega productos para continuar</p>';
        return;
    }

    let total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    
    // Render Items
    listContainer.innerHTML = cart.map(item => `
        <div class="cart-item" style="display:flex; gap:16px; margin-bottom:20px; border-bottom:1px solid #eee; padding-bottom:16px;">
            <img src="${resolveMediaUrl(item)}" style="width:80px; height:80px; object-fit:cover; border-radius:4px;">
            <div style="flex:1">
                <h4 style="font-weight:400;">${item.name}</h4>
                <div style="display:flex; align-items:center; gap:12px; margin-top:8px;">
                     <button onclick="updateQuantity('${item.id}', -1)" style="border:1px solid #ddd; background:none; border-radius:4px; padding:2px 8px;">-</button>
                     <span>${item.quantity}</span>
                     <button onclick="updateQuantity('${item.id}', 1)" style="border:1px solid #ddd; background:none; border-radius:4px; padding:2px 8px;">+</button>
                     <button onclick="removeFromCart('${item.id}')" style="background:none; border:none; color:#3483fa; font-size:0.8rem; cursor:pointer; margin-left:auto;">Eliminar</button>
                </div>
            </div>
            <div style="text-align:right">
                <div style="font-weight:600;">${formatCurrency(item.price * item.quantity)}</div>
            </div>
        </div>
    `).join('');

    // Render Summary
    summaryContainer.innerHTML = `
        <div style="display:flex; justify-content:space-between; margin-bottom:12px;">
            <span>Productos (${cart.reduce((s, i) => s + i.quantity, 0)})</span>
            <span>${formatCurrency(total)}</span>
        </div>
        <div style="display:flex; justify-content:space-between; margin-bottom:24px; color:var(--success); font-weight:600;">
            <span>Envío</span>
            <span>Gratis</span>
        </div>
        <div style="display:flex; justify-content:space-between; border-top:1px solid #eee; padding-top:16px; font-size:1.2rem; font-weight:600;">
            <span>Total</span>
            <span>${formatCurrency(total)}</span>
        </div>
    `;
}

function updateQuantity(id, delta) {
    const item = cart.find(i => i.id === id);
    if (item) {
        item.quantity += delta;
        if (item.quantity <= 0) {
            cart = cart.filter(i => i.id !== id);
        }
        saveCart();
        renderCart();
        updateUI();
    }
}

function removeFromCart(id) {
    cart = cart.filter(item => item.id !== id);
    saveCart();
    renderCart();
    updateUI();
}

// Auth Logic
function toggleAuthMode(mode) {
    const login = document.getElementById('login-form');
    const register = document.getElementById('register-form');
    if (mode === 'register') {
        login.style.display = 'none';
        register.style.display = 'block';
    } else {
        login.style.display = 'block';
        register.style.display = 'none';
    }
}

async function handleLogin(event) {
    event.preventDefault();
    const email = document.getElementById('login-email').value;
    const passwordGroup = document.getElementById('password-group');
    const nextBtn = document.getElementById('login-next-btn');

    if (passwordGroup.style.display === 'none') {
        passwordGroup.style.display = 'block';
        nextBtn.innerText = 'Iniciar Sesión';
        return;
    }

    const password = document.getElementById('login-password').value;
    try {
        const res = await fetch(`${AUTH_URL}/login`, {
            method: 'POST',
            body: JSON.stringify({ email, password })
        });
        const data = await res.json();
        if (data.token) {
            currentUser = data.user;
            token = data.token;
            localStorage.setItem('user', JSON.stringify(currentUser));
            localStorage.setItem('token', token);
            updateUI();
            navigateTo('home');
        } else {
            alert(data.error || 'Error en el login');
            if (data.error === 'Email not verified') {
                document.getElementById('login-form').style.display = 'none';
                document.getElementById('verify-form').style.display = 'block';
            }
        }
    } catch (e) {
        alert('Error de conexión');
    }
}

async function handleRegister(event) {
    event.preventDefault();
    const name = document.getElementById('reg-name').value;
    const email = document.getElementById('reg-email').value;
    const password = document.getElementById('reg-password').value;

    try {
        const res = await fetch(`${AUTH_URL}/register`, {
            method: 'POST',
            body: JSON.stringify({ name, email, password })
        });
        const data = await res.json();
        if (data.userId) {
            document.getElementById('register-form').style.display = 'none';
            document.getElementById('verify-form').style.display = 'block';
            document.getElementById('verify-token').dataset.email = email;
        } else {
            alert(data.error);
        }
    } catch (e) {
        alert('Error de conexión');
    }
}

async function handleVerify(event) {
    event.preventDefault();
    const email = document.getElementById('verify-token').dataset.email;
    const token = document.getElementById('verify-token').value;

    try {
        const res = await fetch(`${AUTH_URL}/verify-email`, {
            method: 'POST',
            body: JSON.stringify({ email, token })
        });
        const data = await res.json();
        if (data.message) {
            alert('¡Email verificado! Ya puedes iniciar sesión.');
            location.reload();
        } else {
            alert(data.error);
        }
    } catch (e) {
        alert('Error de conexión');
    }
}

function renderOrders() {
    // Para el cliente, mostrar sus compras (si está implementado, sino mensaje simple)
    const container = views.cart; // Reusar contenedor para simplicidad o usar uno nuevo
    container.innerHTML = `
        <div class="section-card" style="text-align:center; padding:64px;">
            <span class="material-symbols-outlined" style="font-size:4rem; color:#eee;">receipt_long</span>
            <h2 style="margin-top:16px;">Mis Compras</h2>
            <p style="color:var(--text-dim); margin-bottom:24px;">Aquí verás el estado de tus pedidos.</p>
            <button class="primary-btn" style="max-width:200px; margin:0 auto;" onclick="navigateTo('home')">Volver a la tienda</button>
        </div>
    `;
    Object.keys(views).forEach(v => views[v].classList.remove('active'));
    views.cart.classList.add('active'); 
}

function handleLogout() {
    currentUser = null;
    token = null;
    localStorage.removeItem('user');
    localStorage.removeItem('token');
    location.reload();
}

// UI Helpers
function updateUI() {
    if (cartCountLabel) cartCountLabel.innerText = cart.reduce((sum, i) => sum + i.quantity, 0);
    if (userNameLabel && currentUser) {
        userNameLabel.innerText = currentUser.name.split(' ')[0];
    }
}

// Carousel
function initCarousel() {
    const carousel = document.getElementById('hero-carousel');
    const slides = ['banner1.png', 'banner2.png'];
    carousel.innerHTML = slides.map(s => `<div class="slide" style="background-image: url('${s}')"></div>`).join('');
    
    let currentSlide = 0;
    setInterval(() => {
        currentSlide = (currentSlide + 1) % slides.length;
        carousel.style.transform = `translateX(-${currentSlide * 100}%)`;
    }, 5000);
}

// Checkout & Mercado Pago
async function startCheckout() {
    if (cart.length === 0) {
        alert('Tu carrito está vacío');
        return;
    }

    const name = document.getElementById('check-name').value;
    const phone = document.getElementById('check-phone').value;
    const email = document.getElementById('check-email').value;
    const address = document.getElementById('check-address').value;
    const city = document.getElementById('check-city').value;
    const zip = document.getElementById('check-zip').value;

    if (!name || !phone || !email || !address) {
        alert('Por favor completa los datos obligatorios para el envío.');
        return;
    }

    const total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    
    const orderData = {
        customerName: name,
        customerPhone: phone,
        customerEmail: email,
        shippingAddress: address,
        shippingCity: city,
        shippingZip: zip,
        items: cart.map(item => ({
            productId: item.id,
            name: item.name,
            quantity: item.quantity,
            price: item.price
        })),
        totalAmount: total
    };

    fetch(`${API_URL}/orders/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(orderData)
    })
    .then(res => res.json())
    .then(order => {
        alert('¡Pedido realizado con éxito!');
        cart = [];
        localStorage.removeItem('cart');
        window.location.href = 'success.html';
    })
    .catch(err => {
        console.error('Error al realizar pedido:', err);
        alert('Hubo un error al procesar tu pedido. Por favor intenta de nuevo.');
    });
}
