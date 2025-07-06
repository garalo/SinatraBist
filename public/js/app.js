// BIST Hisse Takip Uygulaması JavaScript

document.addEventListener('DOMContentLoaded', function() {
  // Tablo sıralama fonksiyonu
  const sortableTables = document.querySelectorAll('.sortable');
  
  sortableTables.forEach(table => {
    const headers = table.querySelectorAll('th');
    
    headers.forEach((header, index) => {
      if (header.classList.contains('sortable-header')) {
        header.addEventListener('click', () => {
          sortTable(table, index);
        });
        
        // Sıralanabilir başlıklar için imleç stilini değiştir
        header.style.cursor = 'pointer';
        
        // Sıralama ikonları ekle
        const span = document.createElement('span');
        span.innerHTML = ' &#8597;';
        span.classList.add('sort-icon');
        header.appendChild(span);
      }
    });
  });
  
  // Arama fonksiyonu
  const searchInput = document.getElementById('stockSearch');
  if (searchInput) {
    searchInput.addEventListener('keyup', function() {
      const searchTerm = this.value.toLowerCase();
      const stockTable = document.getElementById('stockTable');
      const rows = stockTable.getElementsByTagName('tr');
      
      for (let i = 1; i < rows.length; i++) {
        const symbol = rows[i].getElementsByTagName('td')[0].textContent.toLowerCase();
        const name = rows[i].getElementsByTagName('td')[1].textContent.toLowerCase();
        
        if (symbol.includes(searchTerm) || name.includes(searchTerm)) {
          rows[i].style.display = '';
        } else {
          rows[i].style.display = 'none';
        }
      }
    });
  }
  
  // Otomatik veri yenileme
  const autoRefresh = document.getElementById('autoRefresh');
  let refreshInterval;
  
  if (autoRefresh) {
    autoRefresh.addEventListener('change', function() {
      if (this.checked) {
        // 5 dakikada bir verileri yenile
        refreshInterval = setInterval(function() {
          fetch('/update_stocks')
            .then(response => {
              if (response.ok) {
                window.location.reload();
              }
            })
            .catch(error => console.error('Veri yenileme hatası:', error));
        }, 300000); // 5 dakika = 300000 ms
      } else {
        clearInterval(refreshInterval);
      }
    });
  }
});

// Tablo sıralama fonksiyonu
function sortTable(table, columnIndex) {
  const tbody = table.querySelector('tbody');
  const rows = Array.from(tbody.querySelectorAll('tr'));
  const headers = table.querySelectorAll('th');
  const header = headers[columnIndex];
  
  // Sıralama yönünü belirle
  const ascending = header.classList.contains('sort-asc') ? false : true;
  
  // Tüm başlıklardan sıralama sınıflarını kaldır
  headers.forEach(h => {
    h.classList.remove('sort-asc', 'sort-desc');
    const icon = h.querySelector('.sort-icon');
    if (icon) icon.innerHTML = ' &#8597;';
  });
  
  // Seçilen başlığa sıralama sınıfı ekle
  header.classList.add(ascending ? 'sort-asc' : 'sort-desc');
  const icon = header.querySelector('.sort-icon');
  if (icon) icon.innerHTML = ascending ? ' &#8593;' : ' &#8595;';
  
  // Satırları sırala
  rows.sort((a, b) => {
    let valueA = a.querySelectorAll('td')[columnIndex].textContent.trim();
    let valueB = b.querySelectorAll('td')[columnIndex].textContent.trim();
    
    // Sayısal değerler için
    if (!isNaN(parseFloat(valueA)) && !isNaN(parseFloat(valueB))) {
      valueA = parseFloat(valueA.replace(/[^\d.-]/g, ''));
      valueB = parseFloat(valueB.replace(/[^\d.-]/g, ''));
      return ascending ? valueA - valueB : valueB - valueA;
    }
    
    // Metin değerleri için
    return ascending ? 
      valueA.localeCompare(valueB, 'tr', { sensitivity: 'base' }) : 
      valueB.localeCompare(valueA, 'tr', { sensitivity: 'base' });
  });
  
  // Sıralanmış satırları tabloya ekle
  rows.forEach(row => tbody.appendChild(row));
}

// Grafik renklendirme yardımcı fonksiyonu
function getChartColors(trend) {
  switch(trend) {
    case 'up':
    case 'strong_up':
    case 'rising':
      return {
        borderColor: 'rgba(40, 167, 69, 1)',
        backgroundColor: 'rgba(40, 167, 69, 0.1)'
      };
    case 'down':
    case 'strong_down':
    case 'falling':
      return {
        borderColor: 'rgba(220, 53, 69, 1)',
        backgroundColor: 'rgba(220, 53, 69, 0.1)'
      };
    default:
      return {
        borderColor: 'rgba(108, 117, 125, 1)',
        backgroundColor: 'rgba(108, 117, 125, 0.1)'
      };
  }
}

// Veri yenileme fonksiyonu
function refreshData() {
  const refreshButton = document.getElementById('refreshButton');
  if (refreshButton) {
    refreshButton.disabled = true;
    refreshButton.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Yenileniyor...';
  }
  
  fetch('/update_stocks')
    .then(response => {
      if (response.ok) {
        window.location.reload();
      } else {
        throw new Error('Veri yenileme başarısız');
      }
    })
    .catch(error => {
      console.error('Veri yenileme hatası:', error);
      if (refreshButton) {
        refreshButton.disabled = false;
        refreshButton.innerHTML = 'Verileri Yenile';
      }
      alert('Veri yenileme sırasında bir hata oluştu. Lütfen tekrar deneyin.');
    });
}