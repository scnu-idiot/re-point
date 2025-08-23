package com.idiot.re_point.point.dto;

import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class PointEarnReceiptRequest {
    private Long amount;
    private String receiptId;
    private String title;
    private String detail;
}