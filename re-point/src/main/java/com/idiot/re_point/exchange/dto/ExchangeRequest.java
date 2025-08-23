// src/main/java/com/idiot/re_point/exchange/dto/ExchangeRequest.java
package com.idiot.re_point.exchange.dto;

import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class ExchangeRequest {
    /** 차감할 포인트 (예: 5000) */
    private long amount;

    /** 어떤 상품/권종인지 선택 식별자(선택) */
    private String productId;

    /** 전달 방식(예: "code") – 콘솔 스냅샷과 맞추려면 "code" 고정 */
    private String deliveryType = "code";

    private String cardId;
}