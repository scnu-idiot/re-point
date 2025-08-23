// src/main/java/com/idiot/re_point/exchange/dto/ExchangeResponse.java
package com.idiot.re_point.exchange.dto;

import lombok.*;

import java.time.Instant;

@Getter @Setter
@Builder
@AllArgsConstructor @NoArgsConstructor
public class ExchangeResponse {
    private String exchangeId;     // 새로 생성된 교환 문서 ID
    private String cardCode;       // 지급한 코드
    private long pointsUsed;       // 사용 포인트
    private long balanceAfter;     // 차감 후 잔액
    private String status;         // COMPLETED
}