// com.idiot.re_point.giftcard.dto.GiftcardUpsertRequest.java
package com.idiot.re_point.giftcard.dto;

import lombok.Getter;
@Getter
public class GiftcardUpsertRequest {
    private String cardName;
    private Long   cardValue;
    private Long   stock;
    private Boolean active;
}