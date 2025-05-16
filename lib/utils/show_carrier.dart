String showCarrier(String carrier) {
  switch (carrier) {
    case 'Novel': return '小說';
    case 'Comic': return '漫畫';
    case 'Original': return '原創';
    case 'Game': return '遊戲';
    default: return carrier; // 返回原始字串
  }
}