
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
const PRODUCTS_URL = '/api/products/';
const CONFIG_URL = '/api/config/';

let products = [];
let cart = [];
let currentCategory = 'all';
let storeContact = {
    name: 'Artesanías Inti',
    email: '',
    phone: ''
};
let paymentInfo = {
    cbu: '',
    alias: '',
    titular: ''
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

    // Payment selector toggle
    document.addEventListener('change', (e) => {
        if (e.target.name === 'payment-method') {
            const transferInfo = document.getElementById('transfer-details');
            transferInfo.style.display = e.target.value === 'Transferencia' ? 'block' : 'none';
        }
    });
});

async function init() {
    console.log('--- Init v1.0.2 ---');
    try {
        // Cargar Productos
        const prodRes = await fetch(PRODUCTS_URL);
        if (prodRes.ok) {
            products = await prodRes.json();
            console.log('Productos cargados:', products.length);
        } else {
            console.warn('Error al cargar productos de la API, usando mock');
            products = MOCK_PRODUCTS;
        }

        // Cargar Configuración
        const confRes = await fetch(CONFIG_URL);
        if (confRes.ok) {
            const data = await confRes.json();
            if (data.contact) storeContact = data.contact;
            if (data.payment) paymentInfo = data.payment;
            updateContactsUI();
        }
    } catch (e) {
        console.warn('Usando datos locales por error de red', e);
        products = MOCK_PRODUCTS;
    }
    renderProducts(products);
}

function resolveImageUrl(product) {
    // 1. Prioridad: mediaUrls[0] o imageFileName (formato servidor)
    let fileName = '';
    if (product.mediaUrls && product.mediaUrls.length > 0) {
        fileName = product.mediaUrls[0];
    } else if (product.imageFileName) {
        fileName = product.imageFileName;
    }

    if (fileName) {
        if (fileName.startsWith('http')) return fileName;
        // Si es una ruta relativa, asumimos que está en /public/media/
        return `/public/media/${fileName.split('/').pop()}`;
    }
    
    // 2. Fallback: imageUrl o image (formatos antiguos/mock)
    const fallback = product.imageUrl || product.image;
    if (fallback) {
        if (fallback.startsWith('http') || fallback.startsWith('data:')) return fallback;
        return `/public/media/${fallback.split('/').pop()}`;
    }

    return 'ic_launcher.png';
}

function isVideo(url) {
    const videoExts = ['.mp4', '.mov', '.avi', '.webm'];
    return videoExts.some(ext => url.toLowerCase().endsWith(ext));
}

function formatCurrency(val) {
    // Formato solicitado: $ 5.000
    const formatted = new Intl.NumberFormat('es-AR', {
        minimumFractionDigits: 0
    }).format(val);
    return `$ ${formatted}`;
}

window.copyToClipboard = (elementId) => {
    const text = document.getElementById(elementId).innerText;
    navigator.clipboard.writeText(text).then(() => {
        const btn = event.target;
        const originalText = btn.innerText;
        btn.innerText = '¡Copiado!';
        setTimeout(() => btn.innerText = originalText, 2000);
    });
};

function updateContactsUI() {
    const waText = document.getElementById('contact-phone-text');
    const emailText = document.getElementById('contact-email-text');
    const waLink = document.getElementById('footer-whatsapp');
    const emailLink = document.getElementById('footer-email');

    if (storeContact.phone) {
        if (waText) waText.innerText = storeContact.phone;
        if (waLink) waLink.href = `https://wa.me/${storeContact.phone.replace(/\D/g, '')}`;
    }
    if (storeContact.email) {
        if (emailText) emailText.innerText = storeContact.email;
        if (emailLink) emailLink.href = `mailto:${storeContact.email}`;
    }

    // Actualizar datos de transferencia en el DOM
    const cbuEl = document.getElementById('display-cbu');
    const aliasEl = document.getElementById('display-alias');
    const titularEl = document.getElementById('display-titular');

    if (cbuEl) cbuEl.innerText = paymentInfo.cbu || 'No configurado';
    if (aliasEl) aliasEl.innerText = paymentInfo.alias || 'No configurado';
    if (titularEl) titularEl.innerText = paymentInfo.titular || 'No configurado';
}

function renderProducts(productsToRender) {
    productGrid.innerHTML = '';
    productsToRender.forEach(product => {
        const card = document.createElement('div');
        card.className = 'product-card';
        const mediaSrc = resolveImageUrl(product);
        const isVid = isVideo(mediaSrc);
        
        card.innerHTML = `
            <div class="card-img">
                ${isVid 
                    ? `<video src="${mediaSrc}" muted loop onmouseover="this.play()" onmouseout="this.pause()"></video>` 
                    : `<img src="${mediaSrc}" alt="${product.name}">`
                }
                <span class="category-badge">${product.category}</span>
            </div>
            <div class="card-info">
                <h4>${product.name}</h4>
                <p>${product.description}</p>
                <div class="card-footer">
                    <span class="price">${formatCurrency(product.price)}</span>
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
        const imgSrc = resolveImageUrl(item);
        div.innerHTML = `
            <img src="${imgSrc}" style="width:50px; height:50px; border-radius:8px; object-fit:cover;">
            <div style="flex:1">
                <h5 style="margin:0; font-size:0.9rem;">${item.name}</h5>
                <p style="font-size:0.8rem; color:var(--text-dim); margin:0">${formatCurrency(item.price)} x ${item.quantity}</p>
            </div>
            <button onclick="removeFromCart('${item.id}')" style="background:none; border:none; color:var(--primary); cursor:pointer;">
                <span class="material-symbols-outlined" style="font-size:1.2rem;">delete</span>
            </button>
        `;
        cartItemsContainer.appendChild(div);
    });
    cartTotal.innerText = formatCurrency(total);
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
    const paymentMethod = document.querySelector('input[name="payment-method"]:checked').value;

    let message = `*Nuevo Pedido - Artesanías Inti*\n\n`;
    message += `👤 *Cliente:* ${name}\n`;
    message += `📍 *Dirección:* ${address}\n`;
    message += `📞 *Teléfono:* ${phone}\n`;
    message += `💳 *Método de Pago:* ${paymentMethod}\n\n`;
    message += `🛍️ *Detalle del Pedido:*\n`;
    
    cart.forEach(item => {
        message += `- ${item.name} (x${item.quantity}): ${ formatCurrency(item.price * item.quantity) }\n`;
    });
    
    message += `\n💰 *TOTAL A PAGAR: ${cartTotal.innerText}*`;

    if (paymentMethod === 'Transferencia') {
        message += `\n\n--- *DATOS PARA TRANSFERENCIA* ---\n`;
        message += `📍 *CBU:* ${paymentInfo.cbu}\n`;
        message += `📍 *Alias:* ${paymentInfo.alias}\n`;
        message += `👤 *Titular:* ${paymentInfo.titular}\n\n`;
        message += `_Por favor, adjunta el comprobante una vez realizada la transferencia._`;
    } else {
        message += `\n\n_Coordinaremos los detalles finales por aquí._`;
    }
    
    const waNumber = storeContact.phone.replace(/\D/g, '');
    const url = `https://wa.me/${waNumber}?text=${encodeURIComponent(message)}`;
    window.open(url, '_blank');
}
