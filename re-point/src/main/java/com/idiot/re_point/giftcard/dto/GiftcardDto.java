package com.idiot.re_point.giftcard.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter @Builder
@AllArgsConstructor @NoArgsConstructor
public class GiftcardDto {
    private String cardId;   // 문서 id: card_5000, card_10000 ...
    private String cardName; // 예: 지역상품권 1만원권
    private Long   cardValue; // 5000, 10000 ...
    private boolean active;
    private Long   stock;    // 재고
}